#!/usr/bin/env python3
"""Genera firebase/database.rules.json (reglas de Realtime Database de DevTándem).

Los valores permitidos de cada opción se leen de los enums de Swift
(DevTandem/Models/ProfileOptions.swift y UserRole.swift), no se escriben a mano.
Los límites coinciden con FieldValidators.swift; DatabaseRulesTests comprueba ambas cosas.

Uso, desde la raíz del repositorio:
    python3 firebase/generate_database_rules.py
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODELS = ROOT / "DevTandem" / "Models"
OUTPUT = ROOT / "firebase" / "database.rules.json"

# Límites (deben coincidir con DevTandem/Validation/FieldValidators.swift).
MAX_NAME = 80
MAX_EMAIL = 254
MAX_COMPANY = 100
MAX_TECHNOLOGIES = 15
MAX_TECHNOLOGY = 30
MAX_INVITE_CODE = 40
GITHUB_PREFIX = "https://github.com/"
MAX_GITHUB_USERNAME = 39


def read_enum_cases(path: Path) -> dict:
    """Devuelve {NombreDelEnum: [rawValue, ...]} para los enums `enum X: String` del archivo.

    Solo admite enums cuyos rawValue son el nombre del caso (sin `= "..."`), que es la
    convención del proyecto; si encuentra otra cosa, se detiene con un error.
    """
    source = path.read_text(encoding="utf-8")
    enums = {}
    for match in re.finditer(r"enum\s+(\w+)\s*:\s*String\b[^{]*\{(.*?)\n\s*var\s+title", source, re.S):
        name, body = match.group(1), match.group(2)
        cases = []
        for line in re.findall(r"^\s*case\s+(.+)$", body, re.M):
            for token in line.split(","):
                token = token.strip()
                if not re.fullmatch(r"[A-Za-z][A-Za-z0-9]*", token):
                    sys.exit(f"Caso no soportado en {name}: {token!r} (¿tiene rawValue explícito?)")
                cases.append(token)
        if not cases:
            sys.exit(f"No se encontraron casos en {name}")
        enums[name] = cases
    return enums


def one_of(values: list) -> str:
    """Expresión que exige un string igual a uno de los valores."""
    return "newData.isString() && newData.val().matches(/^(" + "|".join(values) + ")$/)"


def text_up_to(maximum: int) -> str:
    return f"newData.isString() && newData.val().length > 0 && newData.val().length <= {maximum}"


def technologies_rule() -> dict:
    # Los arrays se guardan con claves "0", "1", ...: al menos el "0" y nunca el índice del máximo.
    return {
        ".validate": f"newData.hasChild('0') && !newData.hasChild('{MAX_TECHNOLOGIES}')",
        "$index": {".validate": text_up_to(MAX_TECHNOLOGY)},
    }


def github_rule() -> str:
    username = f"newData.val().replace('{GITHUB_PREFIX}', '')"
    return (
        f"newData.isString() && newData.val().beginsWith('{GITHUB_PREFIX}')"
        f" && newData.val().length <= {len(GITHUB_PREFIX) + MAX_GITHUB_USERNAME}"
        # replace() borra todas las apariciones: comparar largos asegura que el prefijo esté una sola vez.
        f" && {username}.length == newData.val().length - {len(GITHUB_PREFIX)}"
        f" && !newData.val().contains('--')"
        f" && ({username}.matches(/^[A-Za-z0-9]$/)"
        f" || {username}.matches(/^[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]$/))"
    )


def role_block_rule(roles: list) -> str:
    """El perfil tiene los campos comunes y exactamente el bloque de su rol."""
    alternatives = []
    for role in roles:
        others = [other for other in roles if other != role]
        parts = [f"newData.child('role').val() == '{role}'", f"newData.hasChild('{role}')"]
        parts += [f"!newData.hasChild('{other}')" for other in others]
        alternatives.append("(" + " && ".join(parts) + ")")
    return "newData.hasChildren(['name', 'email', 'role', 'createdAt']) && (" + " || ".join(alternatives) + ")"


def build_rules(options: dict, roles: list) -> dict:
    reject_others = {".validate": False}
    return {
        "rules": {
            ".read": False,
            ".write": False,
            "inviteCodes": {
                ".read": False,
                ".write": False,
            },
            "users": {
                "$uid": {
                    ".read": "auth != null && auth.uid == $uid",
                    # newData.exists(): los clientes no pueden borrar su perfil (.validate no se evalúa al borrar).
                    ".write": "auth != null && auth.uid == $uid && newData.exists()",
                    ".validate": role_block_rule(roles),
                    "name": {".validate": text_up_to(MAX_NAME)},
                    "email": {
                        ".validate": f"newData.isString() && newData.val().length <= {MAX_EMAIL}"
                        " && newData.val().matches(/^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z][a-z]+$/)"
                    },
                    "role": {
                        ".validate": one_of(roles) + " && (!data.exists() || newData.val() == data.val())"
                    },
                    "createdAt": {
                        ".validate": "newData.isNumber() && ((!data.exists() && newData.val() == now)"
                        " || (data.exists() && newData.val() == data.val()))"
                    },
                    "client": {
                        ".validate": "newData.hasChildren(['company', 'industry', 'projectType'])",
                        "company": {".validate": text_up_to(MAX_COMPANY)},
                        "industry": {".validate": one_of(options["ClientIndustry"])},
                        "projectType": {".validate": one_of(options["ProjectType"])},
                        "companySize": {".validate": one_of(options["CompanySize"])},
                        "$other": reject_others,
                    },
                    "junior": {
                        ".validate": "newData.hasChildren(['experience', 'technologies', 'githubURL'])",
                        "experience": {".validate": one_of(options["JuniorExperience"])},
                        "technologies": technologies_rule(),
                        "githubURL": {".validate": github_rule()},
                        "availability": {".validate": one_of(options["WeeklyAvailability"])},
                        "$other": reject_others,
                    },
                    "mentor": {
                        ".validate": "newData.hasChildren(['experience', 'technologies', 'githubURL', 'inviteCode'])",
                        "experience": {".validate": one_of(options["MentorExperience"])},
                        "technologies": technologies_rule(),
                        "githubURL": {".validate": github_rule()},
                        "inviteCode": {
                            ".validate": text_up_to(MAX_INVITE_CODE)
                            + " && newData.val().matches(/^[A-Z0-9_-]+$/)"
                            + " && root.child('inviteCodes/' + newData.val()).val() == true"
                        },
                        "availability": {".validate": one_of(options["ReviewAvailability"])},
                        "$other": reject_others,
                    },
                    "$other": reject_others,
                }
            },
        }
    }


def main() -> None:
    options = read_enum_cases(MODELS / "ProfileOptions.swift")
    roles = read_enum_cases(MODELS / "UserRole.swift").get("UserRole")
    expected = {"ClientIndustry", "ProjectType", "CompanySize", "JuniorExperience",
                "WeeklyAvailability", "MentorExperience", "ReviewAvailability"}
    missing = expected - options.keys()
    if missing or not roles:
        sys.exit(f"Faltan enums: {sorted(missing) or 'UserRole'}")

    rules = build_rules(options, roles)
    OUTPUT.write_text(json.dumps(rules, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Reglas escritas en {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
