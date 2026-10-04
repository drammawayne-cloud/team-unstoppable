# Team Unstoppable Pro DJ & Sound

Requested store: https://1teamunstoppable.com. Supplier automation provider: Inventory Source.

Public category: `/pro-audio.html`. The catalog is a sourcing shortlist, not sellable inventory. Manufacturer model/family research does not prove authorized dropshipping, warranty eligibility, current stock, or supplier pricing. No purchase controls or fabricated prices are published.

## Catalog scope

- DJ controllers, players and mixers: Rane and AlphaTheta/Pioneer DJ, including requested DDJ-1000SRT.
- Powered and passive PA: RCF, Mackie, Yorkville, QSC and additional premium brands when supplier-approved.
- Jamaican-style sound-system components: bass cabinets, mids/tops, amps, sound-system preamps, DSP/crossovers, microphones, racks, cables, power and transport.
- Indoor and outdoor event applications. Outdoor use does not establish weather resistance.

## Inventory Source setup

The account profile company is saved as Team Unstoppable and the website as https://1teamunstoppable.com. Email verification is now recognized: the warning is gone and Select Channel is enabled. The supplier/channel wizard was prepared for Synnex and IS Auto Export, with Full Automation Starter at the review stage ($299 due today and $299/month). No purchase was completed and no feed has been activated.

The authenticated Musical Products directory lists Doba, ALMS Marketplace and Carolina Distribution. Carolina Distribution's profile focuses on hand drums and percussion, so it is not selected for this DJ/PA store. Cross-supplier Rane search returned one PERFORMER listing from Synnex. Synnex is the first pilot candidate: its profile shows Inventory Source integration, dropship allowed, no minimum order and USA shipping. This is not confirmation of authorized Rane resale or coverage of all requested brands. The product's supplier brand field says Strategic Sourcing and it has no image. Manufacturer identity, authorization, warranty, current stock and margins need verification. Private listing identifiers and cost evidence are stored only under ignored data/.

Full Automation includes inventory, order routing and shipment tracking. The official pricing page checked October 4, 2026 lists Starter at $299/month, two integrations, 500 monthly orders, $0.30 additional orders and 250,000 SKUs. No plan was purchased. Custom-site integration needs provider confirmation; do not assume an undocumented API or that this Node/Cloudflare store is a supported plug-and-play channel.

## Required mapping and automation

For every SKU: supplier ID, supplier SKU, manufacturer part number, UPC where supplied, variant, authorized brand, title, licensed image/description, current cost, MAP/minimum price, currency, inventory quantity, timestamp, shipping weight/dimensions, freight rules, destination eligibility, warranty/returns and discontinued status.

Validate imported feeds before publishing. Reject duplicate supplier/SKU pairs and mismatched part numbers. Hide stale, discontinued, unapproved and unavailable products; never infer stock from manufacturer pages. Retail pricing must respect MAP and account for payment fees, supplier fees, freight and an approved margin.

Orders require a verified paid state, stock/price recheck, stable order reference, supplier acknowledgment, and reconciliation before retrying an uncertain submission. Sync tracking and exceptions back to the store. Freight and Jamaica destination support must be confirmed rather than presumed. A compatibility review is required for passive cabinet impedance, amplifier loads, processing, voltage and system bundles.

Activation requires approved supplier accounts, a supported sales-channel integration, secure payment connection, customer policies, signed event verification and end-to-end sandbox/staging inventory/order/tracking tests. No live payment or supplier order automation is implemented by the category page.

The equipment category is deployed to https://1teamunstoppable.com/pro-audio using existing Cloudflare Worker and D1 bindings. Deployment version: 98a04d55-43d8-4449-9250-4fa538e2db76. Five existing server/Cloudflare tests passed; JavaScript syntax checks passed. Browser verified ten candidates, three Rane search results, two bass-filter results, empty-category state, and no horizontal overflow at 390px. Store checkout remains absent.

Sources: https://www.inventorysource.com/pricing-plans/ ; https://www.inventorysource.com/dropship-musical-instruments-and-equipment/ ; https://www.inventorysource.com/custom-integration/

## Latest supplier and connection audit

Mackie keyword search returned 63 results, including unrelated fragrance and networking products. Exact product identity is mandatory. A Synnex Thrash212 GO listing was recorded privately with exact supplier SKU and MPN; it does not match the public Thumpv4 family, so it must not be substituted. Stock, resale authorization, warranty and product imagery remain unverified. Yorkville keyword search returned zero visible results; this only describes the searched directory. RCF returned a count but product details did not render, so no audio match was confirmed.

IS Auto Export documentation describes an automatically updated downloadable catalog link. It does not establish the custom site's order submission/tracking connection. Inventory Source's API and custom integration pages direct those integrations through Flxpoint. Resolve that supported contract before purchasing or building a production adapter.

Run `npm run audit:equipment` to report each public product's exact mapping coverage. It also lists additional sourced candidates separately, so a Thrash speaker cannot silently replace a Thump family. Exit status 2 means incomplete activation; status 1 means malformed or inconsistent mapping data. The audit is offline and never submits supplier orders or changes the live catalog.

Additional sources: https://help.inventorysource.com/article/189-catalog-manager-product-customization ; https://www.inventorysource.com/api/

## Readiness follow-up

Inventory Source displayed a support-submission confirmation. The Integrations page still shows Get Started without active supplier integrations. XDJ-AZ exact search returned zero visible directory matches.

The mapping audit now requires explicit model/variant identity and strict boolean approvals, rejects duplicate SKU or ambiguous product mappings, and requires supported sales-channel, payment and supplier order/tracking test evidence. Five additional regression tests protect wrong-model substitution and false readiness. All ten tests passed; syntax checks passed. The readiness report remains INCOMPLETE with zero sellable public products. These offline tests do not prove external provider transactions.
