import { test } from 'node:test';
import assert from 'node:assert/strict';
import { auditEquipment } from '../scripts/equipment-readiness.mjs';

const catalog = { commerceEnabled: false, products: [{ id: 'requested-thump' }] };
const fixture = () => ({
  integrationActive: true, salesChannelVerified: true, paymentEndToEndPassed: true,
  supplierOrderEndToEndPassed: true,
  mappings: [{ internalProductId: 'requested-thump', inventorySourceSupplierId: 'test-supplier',
    supplierSku: 'test-sku', manufacturerPartNumber: 'test-mpn', identityVerified: true,
    manufacturerAuthorizationVerified: true, stockVerified: true, imageAvailable: true,
    shippingVerified: true, warrantyVerified: true, retailPriceApproved: true, sellable: true }]
});

test('a different model cannot fulfill requested catalog coverage', () => {
  const evidence = fixture(); evidence.mappings[0].internalProductId = 'different-thrash';
  const result = auditEquipment(catalog, evidence);
  assert.equal(result.status, 'INCOMPLETE'); assert.equal(result.readyProducts, 0);
  assert.deepEqual(result.additionalCandidates, ['different-thrash']);
});
test('duplicate supplier SKUs and ambiguous product mappings are invalid', () => {
  const evidence = fixture(); evidence.mappings.push({ ...evidence.mappings[0] });
  const result = auditEquipment(catalog, evidence);
  assert.equal(result.status, 'INVALID'); assert.equal(result.errors.length, 2);
});
test('string flags and missing order proof cannot claim readiness', () => {
  const evidence = fixture(); evidence.mappings[0].stockVerified = 'true';
  delete evidence.supplierOrderEndToEndPassed;
  const result = auditEquipment(catalog, evidence);
  assert.equal(result.status, 'INCOMPLETE');
  assert.ok(result.products[0].pending.includes('current stock'));
  assert.ok(result.products[0].pending.includes('verified supplier order/tracking journey'));
});
test('enabled catalog with missing identity proof is invalid', () => {
  const evidence = fixture(); delete evidence.mappings[0].identityVerified;
  const result = auditEquipment({ ...catalog, commerceEnabled: true }, evidence);
  assert.equal(result.status, 'INVALID'); assert.equal(result.readyProducts, 0);
});
test('complete synthetic evidence passes; empty catalog never claims ready', () => {
  assert.equal(auditEquipment(catalog, fixture()).status, 'READY');
  assert.equal(auditEquipment({ products: [] }, { mappings: [] }).status, 'INCOMPLETE');
});
