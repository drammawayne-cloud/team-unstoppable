import { readFile } from 'node:fs/promises';

// Read-only readiness audit. A supplier listing alone never enables commerce.
const root = new URL('../', import.meta.url);
const catalog = JSON.parse(await readFile(new URL('public/equipment-catalog.json', root)));
const evidence = JSON.parse(await readFile(new URL('data/pro-audio-sourcing.private.json', root)));
const identities = new Set();
const byProduct = new Map();
const errors = [];
for (const mapping of evidence.mappings) {
  const supplier = mapping.inventorySourceSupplierId ?? evidence.inventorySourceSupplierId;
  const key = `${supplier}:${mapping.supplierSku}`;
  if (!supplier || !mapping.supplierSku || !mapping.manufacturerPartNumber) errors.push('Missing supplier identity');
  if (identities.has(key)) errors.push(`Duplicate supplier SKU: ${key}`);
  identities.add(key);
  if (byProduct.has(mapping.internalProductId)) errors.push(`Ambiguous product mapping: ${mapping.internalProductId}`);
  byProduct.set(mapping.internalProductId, mapping);
}
const rows = catalog.products.map(product => {
  const match = byProduct.get(product.id);
  const pending = [];
  if (!match) pending.push('exact supplier SKU');
  else {
    if (!(match.manufacturerAuthorizationVerified ?? evidence.manufacturerAuthorizationVerified)) pending.push('authorized resale');
    if (!match.stockVerified) pending.push('current stock');
    if (!match.imageAvailable) pending.push('licensed imagery');
    if (!match.shippingVerified) pending.push('shipping');
    if (!match.warrantyVerified) pending.push('warranty');
    if (!match.retailPriceApproved) pending.push('retail price/MAP');
    if (!match.sellable) pending.push('activation approval');
  }
  if (!evidence.integrationActive) pending.push('active integration');
  if (!evidence.salesChannelVerified) pending.push('supported sales channel');
  if (!evidence.paymentEndToEndPassed) pending.push('verified payment journey');
  if (!evidence.supplierOrderEndToEndPassed) pending.push('verified supplier order/tracking journey');
  return { product: product.id, listingFound: Boolean(match), ready: pending.length === 0, pending };
});
const extras = evidence.mappings.filter(m => !catalog.products.some(p => p.id === m.internalProductId));
const ready = rows.every(r => r.ready) && !errors.length;
if (catalog.commerceEnabled && !ready) errors.push('Commerce enabled with incomplete mappings');
console.log(JSON.stringify({ status: errors.length ? 'INVALID' : ready ? 'READY' : 'INCOMPLETE', publicProducts: rows.length, readyProducts: rows.filter(r => r.ready).length, products: rows, additionalCandidates: extras.map(m => m.internalProductId), errors }, null, 2));
process.exitCode = errors.length ? 1 : ready ? 0 : 2;
