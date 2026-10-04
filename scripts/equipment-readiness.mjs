// Read-only mapping coverage; never submits orders or enables commerce.
export function auditEquipment(catalog, evidence) {
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
    if (match.identityVerified !== true) pending.push('exact model/variant identity');
    if ((match.manufacturerAuthorizationVerified ?? evidence.manufacturerAuthorizationVerified) !== true) pending.push('authorized resale');
    if (match.stockVerified !== true) pending.push('current stock');
    if (match.imageAvailable !== true) pending.push('licensed imagery');
    if (match.shippingVerified !== true) pending.push('shipping');
    if (match.warrantyVerified !== true) pending.push('warranty');
    if (match.retailPriceApproved !== true) pending.push('retail price/MAP');
    if (match.sellable !== true) pending.push('activation approval');
  }
  if (evidence.integrationActive !== true) pending.push('active integration');
  if (evidence.salesChannelVerified !== true) pending.push('supported sales channel');
  if (evidence.paymentEndToEndPassed !== true) pending.push('verified payment journey');
  if (evidence.supplierOrderEndToEndPassed !== true) pending.push('verified supplier order/tracking journey');
  return { product: product.id, listingFound: Boolean(match), ready: pending.length === 0, pending };
});
const extras = evidence.mappings.filter(m => !catalog.products.some(p => p.id === m.internalProductId));
const ready = rows.length > 0 && rows.every(r => r.ready) && !errors.length;
if (catalog.commerceEnabled && !ready) errors.push('Commerce enabled with incomplete mappings');
return { status: errors.length ? 'INVALID' : ready ? 'READY' : 'INCOMPLETE', publicProducts: rows.length, readyProducts: rows.filter(r => r.ready).length, products: rows, additionalCandidates: extras.map(m => m.internalProductId), errors };
}
