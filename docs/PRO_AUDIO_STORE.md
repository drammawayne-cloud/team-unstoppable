# Team Unstoppable Pro DJ & Sound

Requested store: https://1teamunstoppable.com. Supplier automation provider: Inventory Source.

Public category: `/pro-audio.html`. The catalog is a sourcing shortlist, not sellable inventory. Manufacturer model/family research does not prove authorized dropshipping, warranty eligibility, current stock, or supplier pricing. No purchase controls or fabricated prices are published.

## Catalog scope

- DJ controllers, players and mixers: Rane and AlphaTheta/Pioneer DJ, including requested DDJ-1000SRT.
- Powered and passive PA: RCF, Mackie, Yorkville, QSC and additional premium brands when supplier-approved.
- Jamaican-style sound-system components: bass cabinets, mids/tops, amps, sound-system preamps, DSP/crossovers, microphones, racks, cables, power and transport.
- Indoor and outdoor event applications. Outdoor use does not establish weather resistance.

## Inventory Source setup

The signup store URL is filled as https://1teamunstoppable.com. The account dashboard is accessible. Email verification is pending; Add Integration displays a verification requirement and disables Select Channel and Continue.

The authenticated Musical Products directory lists Doba, ALMS Marketplace and Carolina Distribution. Carolina Distribution's profile focuses on hand drums and percussion, so it is not selected for this DJ/PA store. Cross-supplier Rane search returned one PERFORMER listing from Synnex. Synnex is the first pilot candidate: its profile shows Inventory Source integration, dropship allowed, no minimum order and USA shipping. This is not confirmation of authorized Rane resale or coverage of all requested brands. The product's supplier brand field says Strategic Sourcing and it has no image. Manufacturer identity, authorization, warranty, current stock and margins need verification. Private listing identifiers and cost evidence are stored only under ignored data/.

Full Automation includes inventory, order routing and shipment tracking. The official pricing page checked October 4, 2026 lists Starter at $299/month, two integrations, 500 monthly orders, $0.30 additional orders and 250,000 SKUs. No plan was purchased. Custom-site integration needs provider confirmation; do not assume an undocumented API or that this Node/Cloudflare store is a supported plug-and-play channel.

## Required mapping and automation

For every SKU: supplier ID, supplier SKU, manufacturer part number, UPC where supplied, variant, authorized brand, title, licensed image/description, current cost, MAP/minimum price, currency, inventory quantity, timestamp, shipping weight/dimensions, freight rules, destination eligibility, warranty/returns and discontinued status.

Validate imported feeds before publishing. Reject duplicate supplier/SKU pairs and mismatched part numbers. Hide stale, discontinued, unapproved and unavailable products; never infer stock from manufacturer pages. Retail pricing must respect MAP and account for payment fees, supplier fees, freight and an approved margin.

Orders require a verified paid state, stock/price recheck, stable order reference, supplier acknowledgment, and reconciliation before retrying an uncertain submission. Sync tracking and exceptions back to the store. Freight and Jamaica destination support must be confirmed rather than presumed. A compatibility review is required for passive cabinet impedance, amplifier loads, processing, voltage and system bundles.

Activation requires approved supplier accounts, a supported sales-channel integration, secure payment connection, customer policies, signed event verification and end-to-end sandbox/staging inventory/order/tracking tests. No live payment or supplier order automation is implemented by the category page.

The equipment category is deployed to https://1teamunstoppable.com/pro-audio using existing Cloudflare Worker and D1 bindings. Deployment version: 98a04d55-43d8-4449-9250-4fa538e2db76. Five existing server/Cloudflare tests passed; JavaScript syntax checks passed. Browser verified ten candidates, three Rane search results, two bass-filter results, empty-category state, and no horizontal overflow at 390px. Store checkout remains absent.

Sources: https://www.inventorysource.com/pricing-plans/ ; https://www.inventorysource.com/dropship-musical-instruments-and-equipment/ ; https://www.inventorysource.com/custom-integration/
