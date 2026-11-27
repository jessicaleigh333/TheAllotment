"""Review workbook and precise native-Sheets upload rows; no Google credentials required."""
import argparse
import csv
import io
from pathlib import Path

from tools.botanical.foundation import IntegrityError,digest,strict_json
from .catalog import PROJECT,write_json


def thumbnail(item,output):
    """Render/crop actual existing icon bytes, without generating replacement artwork."""
    from PIL import Image
    icon=item.get("thumbnail",{})
    if not icon:return None
    path=PROJECT/icon["path"].removeprefix("res://")
    if not path.is_file():return None
    if path.suffix==".svg":
        import cairosvg
        image=Image.open(io.BytesIO(cairosvg.svg2png(url=str(path),output_width=64,output_height=64)))
    else:
        image=Image.open(path)
        if icon.get("region"):
            x,y,w,h=icon["region"];image=image.crop((int(x),int(y),int(x+w),int(y+h)))
    image.thumbnail((64,64));image.save(output)
    return output


def create(build,out):
    from openpyxl import Workbook
    from openpyxl.styles import Alignment,Font,PatternFill,Protection
    from openpyxl.worksheet.datavalidation import DataValidation
    from openpyxl.drawing.image import Image
    build,out=Path(build),Path(out)
    if out.exists():raise IntegrityError("Workbook output exists")
    manifest=strict_json((build/"manifest.json").read_text())
    for path,sha in manifest["files"].items():
        if digest((build/path).read_bytes())!=sha:raise IntegrityError("Changed build artifact")
    book=Workbook();intro=book.active;intro.title="Start here"
    intro.append(["The Allotment — Master World Catalog","Review existing items; preserve live IDs and saves"])
    for row in [
        ["Build",manifest["content_hash"]],
        ["How to review","Filter by domain/status. Shop, surface editor, scenery and avatar options are distinct."],
        ["Correct a record","Use Owner Corrections with the item ID and revision from Master Item Catalog."],
        ["Add an item","Use New Item Requests. A request is a proposal, not a live shop listing."],
        ["Current shop","Effective price shows current Rune charges. Legacy prices without a Rune purchase remain free."],
        ["Artwork","Thumbnails render existing icons/atlas cells only; not approved model previews."],
        ["Publication","Review creates an overlay; no direct write to verified game scripts or saves."],
        ["Not implemented","Contracts for sitting, watering, harvesting, repairs, crafting and selling are not functional."],
        ["Protection","Frozen source views are protected against accidental edits; owner permissions are separate."],
    ]:intro.append(row)
    bundle=strict_json((build/"catalog.v1.json").read_text());items={r["item_id"]:r for r in bundle["items"]}
    native=[];images=[];thumb_dir=build/"thumbnails";thumb_dir.mkdir(exist_ok=True)
    for path in sorted((build/"sheets").glob("*.csv")):
        with path.open(newline="",encoding="utf-8") as stream:
            rows=list(csv.reader(stream))
        if path.stem=="Owner Corrections":rows.append(["example-draft","bench",items["bench"]["revision"],"set","owner_notes",'"Add your review note"',"draft","","",""])
        if path.stem=="New Item Requests":rows.append(["example-request","","","","","","draft",""])
        sheet=book.create_sheet(path.stem)
        for row in rows:
            if any(len(cell)>32767 for cell in row):raise IntegrityError("Spreadsheet cell too long")
            sheet.append(row)
        sheet.freeze_panes="C2";sheet.auto_filter.ref=sheet.dimensions
        editable=path.stem in ("Owner Corrections","New Item Requests")
        sheet.protection.sheet=True
        for cell in sheet[1]:
            cell.font=Font(bold=True);cell.fill=PatternFill("solid",fgColor="EEEEEE")
            cell.alignment=Alignment(wrap_text=True,vertical="center")
        sheet.row_dimensions[1].height=32
        for column in sheet.columns:sheet.column_dimensions[column[0].column_letter].width=26
        sheet.column_dimensions["A"].width=30
        for row in sheet.iter_rows(min_row=2):
            for cell in row:cell.alignment=Alignment(vertical="top",wrap_text=False)
        if editable:
            for row in sheet.iter_rows(min_row=2,max_row=501,max_col=sheet.max_column):
                for cell in row:cell.protection=Protection(locked=False);cell.number_format="@"
            column="G" if path.stem=="Owner Corrections" else "G"
            rule=DataValidation(type="list",formula1='"draft,approved,rejected"',allow_blank=True)
            sheet.add_data_validation(rule);rule.add(column+"2:"+column+"501")
        if path.stem=="Artwork Review":
            # Stable ID/row matches; reused thumbnails retain separate item bindings.
            rows[0].append("Actual existing thumbnail")
            sheet.cell(1,len(rows[0]),"Actual existing thumbnail")
            for index,row in enumerate(rows[1:],2):
                file=thumb_dir/(digest(row[0])+".png")
                result=thumbnail(items[row[0]],file)
                if result:
                    image=Image(str(result));image.width=56;image.height=56
                    sheet.add_image(image,"H"+str(index));sheet.row_dimensions[index].height=45
                    images.append({"sheet":"Artwork Review","row":index,"column":8,"file":str(file.resolve()),"item_id":row[0]})
                else:sheet.cell(index,8,"Missing actual image")
        width=max(len(row) for row in rows)
        rows=[row+[""]*(width-len(row)) for row in rows]
        native.append({"title":path.stem,"rows":rows,"editable":editable})
    intro.column_dimensions["A"].width=28;intro.column_dimensions["B"].width=110
    book.save(out)
    write_json(build/"native_sheet_plan.json",{"sheets":[{"title":"Start here","rows":[[c.value or "" for c in row] for row in intro],"editable":False}]+native,"images":images})


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("--build",type=Path,required=True);parser.add_argument("--out",type=Path,required=True)
    args=parser.parse_args();create(args.build,args.out)
