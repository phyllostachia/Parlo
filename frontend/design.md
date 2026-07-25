# Claude — 风格参考
> 温暖的羊皮纸印刷品：骨纸上的墨迹，以 clay 作为唯一的彩色气息。

**Theme：** light

Claude 呈现温暖纸张风格的 editorial interface：用米白色羊皮纸画布（`#f8f8f6`）替代常见的冷白色 SaaS 背景，并配合近黑色的暖 charcoal（`#121212`），让文字看起来像印在纸上的墨迹，而不是玻璃上的像素。整个系统有意保持 monochrome，唯一的彩色 accent 是 clay orange（`#d97757`），只作为标志性点缀使用，不用来铺满 call-to-action。Typography 是核心：Anthropic Serif 负责富有情绪的标题（科技产品中少见的 serif），Anthropic Sans 负责其他内容，并限制在 400-580 字重之间，通过字号和字重对比而非颜色建立层次。Surface 保持平面，使用较大的 corner radius（card 为 16-24px，control 为 8px）、极轻的 shadow 和 hairline border，整体更像印刷文档，而不是数字产品。

## Tokens — Colors

| Name | Value | Token | Role |
|------|-------|-------|------|
| Bone Parchment | `#f8f8f6` | `--color-bone-parchment` | 页面画布、大面积背景、nav bar、次级 card |
| Paper White | `#ffffff` | `--color-paper-white` | 高于画布的 raised card surface、主要 content surface |
| Soft Stone | `#efeeeb` | `--color-soft-stone` | 嵌套 card surface、细微背景变化、交替 section band |
| Carbon Ink | `#121212` | `--color-carbon-ink` | 主要文本、heading、icon fill；是暖近黑色而非纯黑 |
| Graphite | `#373734` | `--color-graphite` | 次级 heading、button text、nav text；比 Carbon Ink 柔和 |
| Ashen | `#7b7974` | `--color-ashen` | 弱化的 helper text、caption、fine print、免责声明 |
| Pebble | `#9c9a92` | `--color-pebble` | 第三级文本、copyright、低优先级 label |
| Mist | `#b7b7b5` | `--color-mist` | hairline nav divider、细微 border line |
| Chalk | `#e7e6e1` | `--color-chalk` | 装饰插图 fill、柔和背景 tint |
| Obsidian | `#000000` | `--color-obsidian` | footer background；页面中唯一的纯黑色 |
| Clay | `#d97757` | `--color-clay` | icon、mark 和小型图形细节使用的橙色装饰 accent，不要将其提升为主要 CTA 颜色 |

## Tokens — Typography

### Anthropic Serif — Display 和 editorial headline（Explore plans、Think fast build faster）

Serif 是品牌标志，在 AI/tech product UI 中较少见；这里用它表达思考感和 editorial confidence，而不是 software utility。· `--font-anthropic-serif`

- **Substitute：** Source Serif 4、Charter、Georgia
- **Weights：** 400
- **Sizes：** 24px、30px
- **Line height：** 1.20-1.33
- **Letter spacing：** normal
- **Role：** Display 和 editorial headline。Serif 是品牌标志，通过字体风格而不是软件感传达思考感和编辑式自信。

### Anthropic Sans — 所有 interface text：body copy、nav、button、card、link、label

580 是最大字重，400 最常用。轻到中等的字重范围通过对比而不是厚重感建立层次；headline 不使用 800 级别的强烈字重，而使用 580。· `--font-anthropic-sans`

- **Substitute：** Inter、IBM Plex Sans、system-ui
- **Weights：** 400、500、550、580、600
- **Sizes：** 11px、12px、14px、15px、16px、24px
- **Line height：** 1.33-1.63
- **Letter spacing：** normal
- **Role：** 所有 interface text：body copy、nav、button、card、link、label。580 是最大字重，400 最常用。

### Type Scale

| Role | Size | Line Height | Letter Spacing | Token |
|------|------|-------------|----------------|-------|
| caption | 11px | 1.5 | — | `--text-caption` |
| body | 14px | 1.5 | — | `--text-body` |
| heading-sm | 24px | 1.33 | — | `--text-heading-sm` |
| heading | 30px | 1.2 | — | `--text-heading` |

## Tokens — Spacing & Shapes

**Base unit：** 8px

**Density：** compact

### Spacing Scale

| Name | Value | Token |
|------|-------|-------|
| 8 | 8px | `--spacing-8` |
| 16 | 16px | `--spacing-16` |
| 24 | 24px | `--spacing-24` |
| 32 | 32px | `--spacing-32` |
| 40 | 40px | `--spacing-40` |
| 64 | 64px | `--spacing-64` |
| 80 | 80px | `--spacing-80` |
| 96 | 96px | `--spacing-96` |

### Border Radius

| Element | Value |
|---------|-------|
| nav | 8px |
| cards | 16px |
| inputs | 8px |
| buttons | 8px |
| elevatedCards | 24px |

### Shadows

| Name | Value | Token |
|------|-------|-------|
| lg | `rgba(0, 0, 0, 0.04) 0px 4px 20px 0px` | `--shadow-lg` |
| lg-2 | `oklab(0.431435 -0.02915 -0.125723 / 0.1) 0px 4px 24px 0px` | `--shadow-lg-2` |

### Layout

- **Page max-width：** 1200px
- **Section gap：** 64-80px
- **Card padding：** 32px
- **Element gap：** 8-12px

## Components

### Filled Dark Button
**Role：** 浅色 surface 上的主要 call-to-action。

使用深色 carbon fill（`#121212` 或近黑色）、暖白色 text（`#f8f8f6` 或 `#fff`）、8px radius、垂直 8px / 水平 20px padding，以及 15px Anthropic Sans、500 字重。深色 fill 上使用暖色文字（`#f8f8f6` 而非纯白）可以避免 button 看起来像普通的深色 UI 元素。

### Pill Navigation Button
**Role：** header bar 中的顶层 nav link。

使用透明 background、Graphite（`#373734`）text、无 border、8px radius 和 15px sans、500 字重。它位于 Bone Parchment 画布（`#f8f8f6`）上，并保留充足的水平 padding。Nav bar 应保持简洁：logo 在左侧，link 居中或靠右，不使用厚重 border 或 fill。

### Pricing Tier Card
**Role：** plan comparison card（Free、Pro、Max）。

在 Bone Parchment 画布上使用白色（`#ffffff`）surface、24px radius 和四边 32px padding。Heading 使用 24-30px Anthropic Serif。Price 使用 Carbon Ink（`#121212`），description 使用 Ashen（`#7b7974`）。默认不使用 shadow；hover 或 featured tier 可以显示带有暖色 oklab 的柔和 4px 24px shadow。可选用 `#e7e6e1` 的 1px hairline border。

### Feature Benefit Card
**Role：** plan 内部 feature list 使用的紧凑 card。

使用 Soft Stone（`#efeeeb`）或 Paper White（`#ffffff`）surface、16px radius 和充足的内部 padding（24-32px）。Checkmark icon 使用 Carbon Ink，14px body text 使用 Graphite。保持平面，不使用 shadow，在画布上形成层叠的纸张效果。

### Editorial Section Header
**Role：** 使用 Anthropic Serif 风格的 section title。

使用 Anthropic Serif、30px、400 字重、1.2 line-height 和 Carbon Ink（`#121212`）。标题后紧跟一条 16px 的简短 Ashen（`#7b7974`）body sentence。与上一个 section 保持 64-80px 的上边距。

### Footer Band
**Role：** 深色 site footer。

使用 Obsidian（`#000000`）background，这是页面中唯一的纯黑色，用来形成明确的色调断层。Text 使用 muted gray（`#9c9a92`），link 使用 Pebble 或更亮的颜色。使用按 product/resource/company 分组的多列 grid，整体使用紧凑的 14px sans。

### Inline Link
**Role：** body copy 中的 text link。

默认使用 Graphite（`#373734`），hover 时变为 Carbon Ink（`#121212`）并带 underline。不使用彩色；系统将 link 视为 typography，而不是彩色 emphasis。对 color/background-color 使用 0.2s ease 的 transition。

### Input Field
**Role：** sign-in 和 signup form 中的 email input。

使用透明或 Paper White fill、Pebble（`#b7b7b5`）或 Mist 的 1px border、8px radius 和 14px sans。Focus ring 使用 cds-focus-shadow pattern：inset page-color ring + outer accent ring + blue glow。不要让状态发生过于明显的颜色变化。

### FAQ Accordion Item
**Role：** FAQ section 中可展开的问题。

Item 之间使用无 border 或 hairline divider；question text 使用 Graphite（`#373734`）和 14-16px sans，body 在下方展开并使用 Carbon Ink（`#121212`）。整个 interaction 使用 Anthropic Sans，FAQ body 不使用 serif。每个 item 保留 24px 的垂直 padding。

### Clay Accent Mark
**Role：** 装饰性的 brand flourish，不是 interactive element。

使用小型 Clay orange（`#d97757`）mark，例如 dot、ornament 和 illustration accent，作为 monochrome system 中唯一的彩色气息。绝不用于 button fill 或大面积 background。

### Status Badge
**Role：** 小型 inline status indicator。

使用 8px radius、11-12px sans、500 字重和低对比度 background tint，text 使用 Carbon Ink 或 Graphite。很少使用彩色，保持 warm-gray family，以匹配 editorial tone。

## Do 和 Don't

### Do
- 使用 Bone Parchment（`#f8f8f6`）作为默认页面画布，大面积 background 不要使用纯白。
- 使用 30px、400 字重、1.2 line-height 的 Anthropic Serif 作为 display headline，让 serif 而不是字重承担表现力。
- 保持 palette monochrome，唯一彩色是 Clay（`#d97757`），只用于装饰 mark 和 editorial accent，绝不用于 button fill。
- Elevated card 使用 24px radius，嵌套或次级 card 使用 16px，所有 button、input 和 nav control 使用 8px。
- 保持充足的 section spacing：major section 之间 64-80px，card padding 32px，component 内 element 之间 8-12px。
- 在 Bone Parchment（`#f8f8f6`）上使用 Carbon Ink（`#121212`）text 和 Paper White（`#ffffff`）card，形成层叠纸张效果。
- 使用暖灰色（Graphite、Ashen、Pebble）建立 text hierarchy，不要引入第二种彩色来强调内容。

### Don't
- 不要使用 Clay orange 或其他彩色作为 button fill；action 在浅色上保持深色，在深色上保持浅色。
- 不要使用纯黑（`#000000`）作为 body text；Carbon Ink（`#121212`）更温暖，呈现的是墨迹而不是虚空。
- 不要将 headline 设为 700 及以上字重；系统对 sans 使用最高 580，对 serif 使用 400。
- 不要给 card 使用厚重 shadow；shadow 只能是低不透明度的柔和 4px、20-24px wash，也可以完全不使用。
- 不要使用冷色 blue 或 green 作为 accent 或 brand color；系统有意保持 warm monochrome。
- 不要使用 Anthropic Sans 设置大型 display headline；serif 是标志，sans 用于功能性文字。
- 不要添加 decorative gradient；设计偏好平面、印刷纸张式的 surface。

## Surfaces

| Level | Name | Value | Purpose |
|-------|------|-------|---------|
| 1 | Page Canvas | `#f8f8f6` | 所有页面的基础 background，即暖米白色羊皮纸 |
| 2 | Card Surface | `#ffffff` | 高于画布的主要 content card |
| 3 | Nested Surface | `#efeeeb` | card 内部的次级 card 或 subsection |
| 4 | Dark Band | `#000000` | footer，唯一的深色 surface，用来形成明确的色调断层 |

## Elevation

- **Feature Card（hover state）：** `rgba(0, 0, 0, 0.04) 0px 4px 20px 0px`
- **Pricing Tier Card（featured/hover）：** `oklab(0.431435 -0.02915 -0.125723 / 0.1) 0px 4px 24px 0px`

## Imagery

Imagery 应当稀疏并保持 editorial tone。Product photography 和 illustration 可以在 hero 或 feature section 中 full-bleed 展示，使用充足的 corner radius（16-24px），不添加 decorative border。Clay orange accent（`#d97757`）只出现在部分 illustration detail 中，例如手、物体和 ornament mark，以强化 warm paper aesthetic。Icon 使用单色 Carbon Ink，以一致的 weight outline 或 fill 展示，不使用多色。整体 density 应较低：大多数 section 以 text 为主，imagery 只作为标点而不是视觉 spectacle。不使用 gradient、glow effect 或 3D render。

## Layout

在 Bone Parchment 画布上使用以 1200px 为 max-width、居中的 contained layout。Hero pattern 是位于大量留白中的居中 editorial headline，使用 Anthropic Serif，首屏下方通常配一张 full-bleed product image。Section 以交替的浅色 band 展开：Bone Parchment 画布上浮动白色 card，偶尔使用 Soft Stone（`#efeeeb`）band 调节视觉节奏。Content arrangement 在居中 stack（headline、FAQ、CTA）和不对称两列布局（左侧 text、右侧 image 的 feature block）之间交替。Pricing 使用三列 card grid（Free、Pro、Max），其中 featured tier elevation 更高。Navigation 是简洁的 top bar：logo 在左，link cluster 在右，不使用厚重 border 或 fill。垂直 spacing 应充足：section 之间 64-80px，card 内 32px，形成印刷页面的节奏，而不是密集的 product UI。

## Agent Prompt Guide

**Quick Color Reference**
- Text（primary）：`#121212`
- Text（secondary）：`#373734`
- Text（muted）：`#7b7974`
- Background（canvas）：`#f8f8f6`
- Background（card）：`#ffffff`
- Border（hairline）：`#b7b7b5` 或 `#e7e6e1`
- Accent（仅用于装饰）：`#d97757`
- primary action：不设置独立的 CTA color

**Example Component Prompts**

1. *Pricing tier card*：在 Bone Parchment 画布（`#f8f8f6`）上使用白色 surface（`#ffffff`）。24px radius，32px padding。Plan name 使用 24px、400 字重的 Anthropic Serif（`#121212`）。Price 使用 24px、580 字重的 Anthropic Sans（`#121212`）。Description 使用 14px sans（`#7b7974`）。底部使用 filled dark button：background `#121212`，text `#f8f8f6`，8px radius，8px/20px padding，15px sans、500 字重。

2. *Editorial hero section*：使用 Bone Parchment（`#f8f8f6`）background，不使用 border。Headline 使用 Anthropic Serif、30px、400 字重（`#121212`），line-height 1.2。Subtext 使用 Anthropic Sans、16px、400 字重（`#373734`）。上下各使用 64-80px vertical padding。Headline 旁可以选择性添加 Clay（`#d97757`）accent dot 或 mark。

3. *FAQ accordion item*：使用透明 background，不使用 card。Question 使用 Anthropic Sans、16px、500 字重（`#373734`）。Body answer 使用 14px、400 字重（`#121212`）。底部使用 `#e7e6e1` 的 1px hairline border。使用 24px vertical padding。不为 chevron icon 设置彩色，使用 Carbon Ink（`#121212`）。

4. *Footer band*：使用 Obsidian（`#000000`）全宽 background。使用三或四列 link。Link text 使用 Pebble（`#9c9a92`）和 14px sans。Copyright 使用 12px sans（`#9c9a92`）。使用 64px vertical padding。Footer link row 中不使用 icon。

5. *Dark navigation button*：使用透明 fill、Graphite（`#373734`）text、8px radius、15px Anthropic Sans、500 字重和 20px horizontal padding。Hover 时以 0.2s ease 过渡到 Carbon Ink（`#121212`）。不使用 border 或 background fill。

## Editorial Typography System

该 design system 的核心特征是有意将 Anthropic Serif（仅用于 headline，400 字重）与 Anthropic Sans（其他所有内容，400-580 字重）配对。Serif 只出现两个字号：24px 和 30px，并且仅用于 section title、plan name 和 editorial hero copy。Sans 覆盖所有 UI role 的 11px 到 24px：body、nav、button、label 和 caption。580 是使用的最大字重，系统不会达到 600 以上。这形成一种只通过 typography contrast 表达权威感的视觉语言，sans 则负责所有功能性表达。重建页面时不要急于增加粗体，应让字号和字重差异建立层次。

## Warm Monochrome Philosophy

Claude 的 palette 有意限制为暖色中性色和一种彩色 accent。近黑色 text color（`#121212`、`#373734`）带有细微暖意，使它们区别于临床感的 SaaS 黑色。Canvas（`#f8f8f6`）和 card surface（`#ffffff`、`#efeeeb`）形成类似纸张的渐变层次：羊皮纸 → 纸张 → vellum。唯一的 accent Clay（`#d97757`）只出现在装饰场景中：小型 mark、illustration detail 和 editorial flourish。它绝不用于填充 button、突出 link 或吸引注意力到数据上。这种克制就是品牌特征。增加其他彩色（例如 link 使用 blue、success 使用 green、error 使用 red）会破坏系统的 editorial integrity。

## Similar Brands

- **Stripe** — 同样使用暖米白画布（约 `#fbf9f6`）、充足留白、带柔和 radius 的平面 card，并克制使用颜色；Stripe 在 marketing surface 中也几乎保持 monochrome palette。
- **Linear** — 擅长 dark/light mode，使用极少彩色 accent、较大的 card radius（16-24px）和紧凑的 typographic hierarchy；但 Linear 更偏深色，而 Claude 更偏 warm-paper。
- **Notion** — editorial restraint：monochrome palette、充足 spacing，以及优先考虑可读性而非视觉 spectacle 的可选 serif typography。
- **Arc Browser** — warm-paper aesthetic、接近 clay 的 accent palette、具有 editorial confidence 的 typography，并拒绝将典型 SaaS blue 作为 brand color。

## Quick Start

### CSS Custom Properties

```css
:root {
  /* 颜色 */
  --color-bone-parchment: #f8f8f6;
  --color-paper-white: #ffffff;
  --color-soft-stone: #efeeeb;
  --color-carbon-ink: #121212;
  --color-graphite: #373734;
  --color-ashen: #7b7974;
  --color-pebble: #9c9a92;
  --color-mist: #b7b7b5;
  --color-chalk: #e7e6e1;
  --color-obsidian: #000000;
  --color-clay: #d97757;

  /* Typography — Font Families */
  --font-anthropic-serif: 'Anthropic Serif', ui-serif, Georgia, Cambria, "Times New Roman", Times, serif;
  --font-anthropic-sans: 'Anthropic Sans', ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;

  /* Typography — Scale */
  --text-caption: 11px;
  --leading-caption: 1.5;
  --text-body: 14px;
  --leading-body: 1.5;
  --text-heading-sm: 24px;
  --leading-heading-sm: 1.33;
  --text-heading: 30px;
  --leading-heading: 1.2;

  /* Typography — Weights */
  --font-weight-regular: 400;
  --font-weight-medium: 500;
  --font-weight-w550: 550;
  --font-weight-w580: 580;
  --font-weight-semibold: 600;

  /* 间距 */
  --spacing-unit: 8px;
  --spacing-8: 8px;
  --spacing-16: 16px;
  --spacing-24: 24px;
  --spacing-32: 32px;
  --spacing-40: 40px;
  --spacing-64: 64px;
  --spacing-80: 80px;
  --spacing-96: 96px;

  /* 布局 */
  --page-max-width: 1200px;
  --section-gap: 64-80px;
  --card-padding: 32px;
  --element-gap: 8-12px;

  /* Border Radius */
  --radius-lg: 8px;
  --radius-2xl: 16px;
  --radius-3xl: 24px;

  /* Named Radii */
  --radius-nav: 8px;
  --radius-cards: 16px;
  --radius-inputs: 8px;
  --radius-buttons: 8px;
  --radius-elevatedcards: 24px;

  /* 阴影 */
  --shadow-lg: rgba(0, 0, 0, 0.04) 0px 4px 20px 0px;
  --shadow-lg-2: oklab(0.431435 -0.02915 -0.125723 / 0.1) 0px 4px 24px 0px;

  /* Surface */
  --surface-page-canvas: #f8f8f6;
  --surface-card-surface: #ffffff;
  --surface-nested-surface: #efeeeb;
  --surface-dark-band: #000000;
}
```

### Tailwind v4

```css
@theme {
  /* 颜色 */
  --color-bone-parchment: #f8f8f6;
  --color-paper-white: #ffffff;
  --color-soft-stone: #efeeeb;
  --color-carbon-ink: #121212;
  --color-graphite: #373734;
  --color-ashen: #7b7974;
  --color-pebble: #9c9a92;
  --color-mist: #b7b7b5;
  --color-chalk: #e7e6e1;
  --color-obsidian: #000000;
  --color-clay: #d97757;

  /* Typography */
  --font-anthropic-serif: 'Anthropic Serif', ui-serif, Georgia, Cambria, "Times New Roman", Times, serif;
  --font-anthropic-sans: 'Anthropic Sans', ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;

  /* Typography — Scale */
  --text-caption: 11px;
  --leading-caption: 1.5;
  --text-body: 14px;
  --leading-body: 1.5;
  --text-heading-sm: 24px;
  --leading-heading-sm: 1.33;
  --text-heading: 30px;
  --leading-heading: 1.2;

  /* 间距 */
  --spacing-8: 8px;
  --spacing-16: 16px;
  --spacing-24: 24px;
  --spacing-32: 32px;
  --spacing-40: 40px;
  --spacing-64: 64px;
  --spacing-80: 80px;
  --spacing-96: 96px;

  /* Border Radius */
  --radius-lg: 8px;
  --radius-2xl: 16px;
  --radius-3xl: 24px;

  /* 阴影 */
  --shadow-lg: rgba(0, 0, 0, 0.04) 0px 4px 20px 0px;
  --shadow-lg-2: oklab(0.431435 -0.02915 -0.125723 / 0.1) 0px 4px 24px 0px;
}
```
