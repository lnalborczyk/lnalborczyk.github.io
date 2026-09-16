from pathlib import Path
import xml.etree.ElementTree as ET

sitemap = Path("docs/sitemap.xml")

if sitemap.exists():
    ET.register_namespace("", "http://www.sitemaps.org/schemas/sitemap/0.9")
    tree = ET.parse(sitemap)
    root = tree.getroot()

    ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}

    for url in list(root.findall("sm:url", ns)):
        loc = url.find("sm:loc", ns)

        if loc is not None and "/internal/" in loc.text:
            root.remove(url)

    tree.write(
        sitemap,
        encoding="UTF-8",
        xml_declaration=True
        )
