#!/usr/bin/env python3
"""Build downloadable drmTMB function-map and cheatsheet PDFs."""

from __future__ import annotations

import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A3, A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfgen import canvas
from reportlab.platypus import (
    CondPageBreak,
    Image,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "function-cheatsheet-source.Rmd"
OUTPUT = ROOT / "pkgdown" / "assets" / "cheatsheets"
SITE = "https://itchyshin.github.io/drmTMB"
LOGO = ROOT / "man" / "figures" / "drmTMB-logo.png"
MAP_IMAGE = ROOT / "vignettes" / "articles" / "function-map-cheatsheet.png"


def package_version() -> str:
    description = (ROOT / "DESCRIPTION").read_text(encoding="utf-8")
    match = re.search(r"^Version:\s*(\S+)", description, flags=re.MULTILINE)
    if not match:
        raise SystemExit("DESCRIPTION does not contain Version")
    return match.group(1)

INK = colors.HexColor("#173042")
MUTED = colors.HexColor("#536875")
TEAL = colors.HexColor("#0F7887")
LINE = colors.HexColor("#DCE4E8")

PALETTE = {
    "spec": ("#75A843", "#476F1F", "#F4F8EF"),
    "fit": ("#4E86BF", "#245C91", "#EFF5FB"),
    "inspect": ("#8464AD", "#5B3C82", "#F5F1FA"),
    "infer": ("#DF8A45", "#9A501D", "#FDF5EC"),
    "predict": ("#31A0A0", "#126E70", "#EFF8F7"),
    "visual": ("#C56B8C", "#8F3E5E", "#FBF1F5"),
}

MAP_MAIN = [
    (
        "spec",
        "1. SPECIFY",
        [
            ("drm_formula() / bf()", "Join one formula per distributional parameter."),
            ("Family constructors", "Choose the response or missing-predictor family."),
            ("meta_V(), miss_control()", "Supply known covariance or a missing-data policy."),
            ("phylo(), spatial(), animal(), relmat()", "Add documented structural dependence."),
        ],
    ),
    (
        "fit",
        "2. FIT",
        [
            ("drmTMB()", "Fit with the native TMB engine by default."),
            ("drm_control()", "Control optimization, storage, and large-data options."),
            ("drm_phylo_penalty()", "Define the documented penalized/MAP workflow."),
            ("drm_phylo_penalty_sweep()", "Check sensitivity to the correlation penalty."),
        ],
    ),
    (
        "inspect",
        "3. CHECK & EXTRACT",
        [
            ("check_drm(), is_converged()", "Check convergence, Hessian, gradients, and boundaries."),
            ("summary(), coef(), fixef(), ranef()", "Inspect coefficients and random effects."),
            ("sigma(), rho12(), corpairs(), structured_effects()", "Extract scale, correlation, and structured-effect summaries."),
            ("imputed()", "Inspect fitted values for modelled missing predictors."),
            ("logLik(), AIC(), BIC(), vcov()", "Extract standard model-fit summaries."),
        ],
    ),
    (
        "predict",
        "4. PREDICT & SIMULATE",
        [
            ("prediction_grid()", "Construct a controlled new-data grid."),
            ("predict(), predict_parameters()", "Predict responses or named parameters."),
            ("simulate()", "Draw new responses from a fitted model."),
            ("marginal_parameters()", "Compute plug-in averages of fitted parameters."),
        ],
    ),
    (
        "visual",
        "5. VISUALIZE",
        [
            ("plot(profile(fit, ...))", "Show the likelihood-ratio curve and cutoff."),
            ("plot_corpairs()", "Plot fitted latent correlation-pair summaries."),
            ("plot_parameter_surface()", "Plot fitted parameters over a prediction grid."),
        ],
    ),
]

MAP_SUPPORT = [
    (
        "spec",
        "RESPONSE FAMILIES",
        [
            ("student(), skew_normal(), lognormal(), tweedie()", "Continuous and semicontinuous responses."),
            ("beta(), zero_one_beta(), beta_binomial()", "Proportions and success counts."),
            ("nbinom2(), truncated_nbinom2()", "Ordinary, hurdle, or positive counts."),
            ("categorical(), cumulative_logit(), biv_gaussian()", "Categorical imputation, ordinal, or paired Gaussian responses."),
        ],
    ),
    (
        "spec",
        "DATA & STRUCTURE HELPERS",
        [
            ("meta_V(), meta_vcov_bivariate()", "Supply known sampling covariance."),
            ("miss_control(), mi(), impute_model()", "Choose and specify missing-data routes."),
            ("phylo(), phylo_interaction(), spatial()", "Add tree or coordinate structure."),
            ("animal(), relmat()", "Add pedigree or supplied relationship structure."),
        ],
    ),
    (
        "infer",
        "INFERENCE",
        [
            ("confint()", "Request available Wald, profile, or bootstrap intervals."),
            ("profile_targets(), profile()", "Discover targets and compute likelihood profiles."),
            ("plot(profile(fit, ...))", "Visualize likelihood-ratio profiles and cutoffs."),
        ],
    ),
    (
        "predict",
        "FORMULA & ENGINE HELPERS",
        [
            ("sd(group), sd1(group), sd2(group)", "Formula markers for Gaussian location random-effect scales."),
            ("corpair()", "Formula marker for current q=2 latent-correlation routes."),
            ("rho_latent()", "Optional extractor for supported Julia fits."),
        ],
    ),
]


def register_fonts() -> tuple[str, str]:
    """Use bundled DejaVu fonts when available, otherwise Helvetica."""
    candidates = [
        Path("/System/Library/Fonts/Supplemental/Arial.ttf"),
        Path("/Library/Fonts/Arial.ttf"),
    ]
    bold_candidates = [
        Path("/System/Library/Fonts/Supplemental/Arial Bold.ttf"),
        Path("/Library/Fonts/Arial Bold.ttf"),
    ]
    regular = next((p for p in candidates if p.exists()), None)
    bold = next((p for p in bold_candidates if p.exists()), None)
    if regular and bold:
        pdfmetrics.registerFont(TTFont("DrmSans", str(regular)))
        pdfmetrics.registerFont(TTFont("DrmSans-Bold", str(bold)))
        return "DrmSans", "DrmSans-Bold"
    return "Helvetica", "Helvetica-Bold"


FONT, FONT_BOLD = register_fonts()


def paragraph(text: str, size: float, colour=INK, bold: bool = False, leading=None):
    style = ParagraphStyle(
        "inline",
        fontName=FONT_BOLD if bold else FONT,
        fontSize=size,
        leading=leading or size * 1.2,
        textColor=colour,
        alignment=TA_LEFT,
        spaceAfter=0,
        spaceBefore=0,
    )
    return Paragraph(text, style)


def draw_panel(c, x, y, width, height, key, title, nodes):
    accent, dark, wash = (colors.HexColor(v) for v in PALETTE[key])
    c.setFillColor(wash)
    c.setStrokeColor(accent)
    c.setLineWidth(1.3)
    c.roundRect(x, y, width, height, 10, fill=1, stroke=1)
    c.setFillColor(dark)
    c.setFont(FONT_BOLD, 12)
    c.drawString(x + 12, y + height - 21, title)

    gap = 7
    top = y + height - 34
    node_height = (height - 47 - gap * (len(nodes) - 1)) / len(nodes)
    for name, description in nodes:
        node_y = top - node_height
        c.setFillColor(colors.white)
        c.setStrokeColor(colors.Color(accent.red, accent.green, accent.blue, alpha=0.35))
        c.roundRect(x + 10, node_y, width - 20, node_height, 7, fill=1, stroke=1)
        name_p = paragraph(f"<b>{name}</b>", 9.2, dark, leading=10.5)
        desc_p = paragraph(description, 8.2, MUTED, leading=10)
        inner_w = width - 34
        _, name_h = name_p.wrap(inner_w, node_height)
        _, desc_h = desc_p.wrap(inner_w, node_height)
        content_h = name_h + 3 + desc_h
        start_y = node_y + (node_height + content_h) / 2 - name_h
        name_p.drawOn(c, x + 17, start_y)
        desc_p.drawOn(c, x + 17, start_y - 3 - desc_h)
        top = node_y - gap


def build_map_pdf(path: Path):
    if not MAP_IMAGE.exists():
        raise SystemExit(f"Original function map is missing: {MAP_IMAGE}")
    page_w, page_h = 12 * 72, 8 * 72
    c = canvas.Canvas(str(path), pagesize=(page_w, page_h))
    c.setTitle("drmTMB function map")
    c.setAuthor("drmTMB contributors")
    c.setSubject("Original audited drmTMB workflow map")
    c.drawImage(str(MAP_IMAGE), 0, 0, width=page_w, height=page_h, preserveAspectRatio=True, mask="auto")
    c.save()


def clean_inline(text: str) -> str:
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = text.replace("&gt;", ">").replace("&lt;", "<")
    return text.strip()


def parse_cheatsheet_tables(source: str):
    sections = []
    current = None
    for line in source.splitlines():
        heading = re.match(r"^#{2,3} (.+)$", line)
        if heading:
            current = {"title": heading.group(1), "rows": []}
            sections.append(current)
            continue
        if not current or not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) != 2 or cells[0] in {
            "Function", "Function or syntax", "Syntax", "Task and code", "Item"
        }:
            continue
        if set(cells[0]) <= {"-", ":"}:
            continue
        match = re.search(r"\[([^]]+)\]\(([^)]+)\)", cells[0])
        if not match:
            continue
        label = clean_inline(match.group(1))
        relative = match.group(2).replace("..", "")
        url = SITE + (relative if relative.startswith("/") else f"/articles/{relative}")
        current["rows"].append((label, clean_inline(cells[1]), url))
    return [section for section in sections if section["rows"]]


def draw_cheatsheet_header(c, page_no: int):
    page_w, page_h = landscape(A4)
    if LOGO.exists():
        c.drawImage(str(LOGO), 18 * mm, page_h - 20 * mm, 13 * mm, 13 * mm, mask="auto")
        title_x = 34 * mm
    else:
        title_x = 18 * mm
    c.setFillColor(INK)
    c.setFont(FONT_BOLD, 18)
    c.drawString(title_x, page_h - 13 * mm, "drmTMB : : CHEAT SHEET")
    c.setFillColor(MUTED)
    c.setFont(FONT, 8.2)
    c.drawString(title_x, page_h - 18 * mm, "Distributional regression with Template Model Builder")
    c.drawRightString(page_w - 18 * mm, page_h - 13 * mm, f"PAGE {page_no} OF 2")
    c.drawRightString(page_w - 18 * mm, page_h - 18 * mm, f"drmTMB {package_version()}")
    c.setStrokeColor(LINE)
    c.line(18 * mm, page_h - 22 * mm, page_w - 18 * mm, page_h - 22 * mm)


def draw_cheatsheet_footer(c):
    page_w, _ = landscape(A4)
    c.setStrokeColor(LINE)
    c.line(18 * mm, 12 * mm, page_w - 18 * mm, 12 * mm)
    c.setFillColor(MUTED)
    c.setFont(FONT, 6.8)
    c.drawString(18 * mm, 7.5 * mm, "Deprecated compatibility markers omitted. Navigation guide, not a capability claim.")
    c.drawRightString(page_w - 18 * mm, 7.5 * mm, f"{SITE}/articles/function-map-cheatsheet.html")


def draw_cheatsheet_section(c, x, y_top, width, title, rows, key, row_padding=7):
    accent, dark, wash = (colors.HexColor(v) for v in PALETTE[key])
    name_width = width * 0.39
    desc_width = width - name_width - 18
    rendered = []
    for label, description, url in rows:
        name_p = paragraph(
            f'<link href="{url}" color="{PALETTE[key][1]}"><b>{label}</b></link>',
            7.2,
            dark,
            leading=8.5,
        )
        desc_p = paragraph(description, 6.9, INK, leading=8.4)
        _, name_h = name_p.wrap(name_width, 100)
        _, desc_h = desc_p.wrap(desc_width, 100)
        rendered.append((name_p, desc_p, max(name_h, desc_h) + row_padding))

    header_h = 20
    total_h = header_h + sum(item[2] for item in rendered) + 5
    y_bottom = y_top - total_h
    c.setFillColor(wash)
    c.setStrokeColor(accent)
    c.setLineWidth(0.8)
    c.roundRect(x, y_bottom, width, total_h, 7, fill=1, stroke=1)
    c.setFillColor(dark)
    c.roundRect(x, y_top - header_h, width, header_h, 7, fill=1, stroke=0)
    c.rect(x, y_top - header_h, width, 7, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.setFont(FONT_BOLD, 9)
    c.drawString(x + 8, y_top - 14, title.upper())

    cursor = y_top - header_h
    for i, (name_p, desc_p, row_h) in enumerate(rendered):
        cursor -= row_h
        if i % 2 == 0:
            c.setFillColor(colors.Color(1, 1, 1, alpha=0.62))
            c.rect(x + 1, cursor, width - 2, row_h, fill=1, stroke=0)
        c.setStrokeColor(colors.Color(accent.red, accent.green, accent.blue, alpha=0.22))
        c.line(x + 7, cursor, x + width - 7, cursor)
        name_p.wrapOn(c, name_width, row_h)
        desc_p.wrapOn(c, desc_width, row_h)
        name_p.drawOn(c, x + 7, cursor + (row_h - name_p.height) / 2)
        desc_p.drawOn(c, x + 11 + name_width, cursor + (row_h - desc_p.height) / 2)
    return y_bottom - 7


def build_cheatsheet_pdf(path: Path, source: str):
    sections = {section["title"]: section["rows"] for section in parse_cheatsheet_tables(source)}
    page_w, page_h = landscape(A4)
    c = canvas.Canvas(str(path), pagesize=(page_w, page_h))
    c.setTitle("drmTMB function cheatsheet")
    c.setAuthor("drmTMB contributors")
    c.setSubject("Current non-deprecated functions and fitted-model methods")

    margin = 18 * mm
    gap = 5 * mm
    col_w = (page_w - 2 * margin - 2 * gap) / 3
    top = page_h - 27 * mm

    c.setFillColor(colors.white)
    c.rect(0, 0, page_w, page_h, fill=1, stroke=0)
    draw_cheatsheet_header(c, 1)
    page1 = [
        ("Model specification", "spec"),
        ("Response and predictor families", "fit"),
        ("Random and structured effects", "inspect"),
    ]
    for col, (section, key) in enumerate(page1):
        x = margin + col * (col_w + gap)
        y = draw_cheatsheet_section(c, x, top, col_w, section, sections[section], key)
        if col == 0:
            y = draw_cheatsheet_section(c, x, y, col_w, "Paired-outcome association", sections["Paired-outcome association"], "visual")
            draw_cheatsheet_section(c, x, y, col_w, "Optional Julia extractor", sections["Optional Julia engine"], "visual")
        if col == 2:
            draw_cheatsheet_section(
                c, x, y, col_w, "Distributional assessment",
                sections["Distributional assessment"], "predict", row_padding=0
            )
    draw_cheatsheet_footer(c)
    c.showPage()

    c.setFillColor(colors.white)
    c.rect(0, 0, page_w, page_h, fill=1, stroke=0)
    draw_cheatsheet_header(c, 2)
    checks = sections["Check, summarize, and extract"]
    split = (len(checks) + 1) // 2
    y1 = draw_cheatsheet_section(c, margin, top, col_w, "Check and extract - core", checks[:split], "inspect")
    draw_cheatsheet_section(c, margin, y1, col_w, "Formula anatomy", sections["Formula anatomy"], "spec")

    second_x = margin + col_w + gap
    y2 = draw_cheatsheet_section(c, second_x, top, col_w, "Check and extract - fit", checks[split:], "infer")
    draw_cheatsheet_section(c, second_x, y2, col_w, "Quick ecological recipes", sections["Quick ecological recipes"], "fit")
    third_x = margin + 2 * (col_w + gap)
    y = draw_cheatsheet_section(c, third_x, top, col_w, "Intervals and profiles", sections["Intervals and likelihood profiles"], "infer")
    y = draw_cheatsheet_section(c, third_x, y, col_w, "Predict, simulate, plot", sections["Prediction, simulation, and plots"], "predict")
    draw_cheatsheet_section(c, third_x, y, col_w, "Interpretation guardrails", sections["Interpretation guardrails"], "visual")
    draw_cheatsheet_footer(c)
    c.save()


def validate_surface(source: str):
    namespace = (ROOT / "NAMESPACE").read_text(encoding="utf-8")
    exports = set(re.findall(r"^export\(([^)]+)\)$", namespace, flags=re.MULTILINE))
    expected = exports - {"gr", "meta_known_V"}
    missing = sorted(name for name in expected if f"{name}()" not in source)
    if missing:
        raise SystemExit(f"Function-map source omits current exports: {', '.join(missing)}")


def main():
    source = SOURCE.read_text(encoding="utf-8")
    validate_surface(source)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    map_pdf = OUTPUT / "drmTMB-function-map.pdf"
    cheatsheet_pdf = OUTPUT / "drmTMB-function-cheatsheet.pdf"
    build_map_pdf(map_pdf)
    build_cheatsheet_pdf(cheatsheet_pdf, source)
    print(map_pdf)
    print(cheatsheet_pdf)


if __name__ == "__main__":
    main()
