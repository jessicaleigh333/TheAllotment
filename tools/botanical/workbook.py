"""Create an importable Google Sheets workbook; never connects or writes to Google."""
import argparse
import csv
from pathlib import Path

from .foundation import IntegrityError, digest, strict_json


def workbook(build, out):
    from openpyxl import Workbook
    from openpyxl.styles import Font, PatternFill, Protection
    from openpyxl.worksheet.datavalidation import DataValidation

    build, out = Path(build), Path(out)
    if out.exists():
        raise IntegrityError("Workbook destination must not exist")
    manifest = strict_json((build / "manifest.json").read_text())
    if manifest["schema_version"] != "1.0.0":
        raise IntegrityError("Unsupported build schema")
    book = Workbook()
    instructions = book.active
    instructions.title = "Read me"
    for row in [
        ["The Allotment — Botanical Review", "Research intake; no live gameplay changes"],
        ["Build", manifest["input_hash"]],
        ["Edit workflow", "Inspect tabs; propose edits in Changes. Export Changes as CSV for validated review."],
        ["Identity changes/new records", "Record as owner notes for separate identity/schema review; not automatically applied."],
        ["Approval", "decision=approved, reviewer, UTC reviewed_at, reason and evidence_url are required."],
        ["Value", "proposed_json is JSON: quoted text, numeric value, or explicit null with operation=clear."],
        ["Blank", "Blank rows and draft changes are not source deletions."],
        ["Protection", "Sheet protection prevents accidental edits; Google permissions remain a separate owner task."],
        ["Publication", "Owner change approval does not approve scientific simulation, artwork, or game publication."],
        ["Artwork", "November 14 rose originals remain unlocated; no image/model approval is claimed."],
    ]:
        instructions.append(row)
    for path in sorted((build / "sheets").glob("*.csv")):
        if digest(path.read_bytes()) != manifest["files"][path.relative_to(build).as_posix()]:
            raise IntegrityError("CSV differs from validated build")
        sheet = book.create_sheet(path.stem)
        with path.open(newline="", encoding="utf-8") as stream:
            for row in csv.reader(stream):
                if any(len(cell) > 32767 for cell in row):
                    raise IntegrityError("Cell exceeds spreadsheet limit; use normalized JSON query instead")
                sheet.append(row)
        sheet.freeze_panes = "B2"
        sheet.auto_filter.ref = sheet.dimensions
        sheet.protection.sheet = True
        for cell in sheet[1]:
            cell.font = Font(color="FFFFFF", bold=True)
            cell.fill = PatternFill("solid", fgColor="355E3B")
        for column in sheet.columns:
            sheet.column_dimensions[column[0].column_letter].width = 28
        if path.stem == "Changes":
            for row in sheet.iter_rows(min_row=2, max_row=1001, max_col=sheet.max_column):
                for cell in row:
                    cell.protection = Protection(locked=False)
                    cell.number_format = "@"
            for col, choices in (("F", '"set,clear"'), ("H", '"draft,approved,rejected"')):
                validation = DataValidation(type="list", formula1=choices, allow_blank=True)
                validation.errorTitle = "Choose a supported value"
                validation.error = "Use one of the listed review values."
                validation.showErrorMessage = True
                sheet.add_data_validation(validation)
                validation.add(f"{col}2:{col}1001")
    instructions.column_dimensions["A"].width = 30
    instructions.column_dimensions["B"].width = 110
    book.save(out)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    workbook(args.build, args.out)
