import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test plot registration",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test successful plot registration
    let block = chain.mineBlock([
      Tx.contractCall('harvest-pro', 'register-plot', 
        [types.ascii("PLOT-001"), types.ascii("Test Plot")],
        deployer.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Test duplicate plot registration (should fail)
    block = chain.mineBlock([
      Tx.contractCall('harvest-pro', 'register-plot',
        [types.ascii("PLOT-001"), types.ascii("Test Plot 2")],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(101);
  }
});

Clarinet.test({
  name: "Test harvest recording",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Register plot first
    let block = chain.mineBlock([
      Tx.contractCall('harvest-pro', 'register-plot',
        [types.ascii("PLOT-001"), types.ascii("Test Plot")],
        deployer.address
      )
    ]);
    
    // Test successful harvest recording
    block = chain.mineBlock([
      Tx.contractCall('harvest-pro', 'record-harvest',
        [
          types.ascii("PLOT-001"),
          types.uint(5000),
          types.ascii("Corn"),
          types.uint(1654012800)
        ],
        deployer.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Test unauthorized harvest recording (should fail)
    block = chain.mineBlock([
      Tx.contractCall('harvest-pro', 'record-harvest',
        [
          types.ascii("PLOT-001"),
          types.uint(3000),
          types.ascii("Corn"),
          types.uint(1654099200)
        ],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

Clarinet.test({
  name: "Test data retrieval functions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Setup test data
    let block = chain.mineBlock([
      Tx.contractCall('harvest-pro', 'register-plot',
        [types.ascii("PLOT-001"), types.ascii("Test Plot")],
        deployer.address
      ),
      Tx.contractCall('harvest-pro', 'record-harvest',
        [
          types.ascii("PLOT-001"),
          types.uint(5000),
          types.ascii("Corn"),
          types.uint(1654012800)
        ],
        deployer.address
      )
    ]);
    
    // Test plot data retrieval
    let response = chain.callReadOnlyFn(
      'harvest-pro',
      'get-plot-data',
      [types.ascii("PLOT-001")],
      deployer.address
    );
    response.result.expectSome();
    
    // Test harvest data retrieval
    response = chain.callReadOnlyFn(
      'harvest-pro',
      'get-harvest-data',
      [types.ascii("PLOT-001"), types.uint(1654012800)],
      deployer.address
    );
    response.result.expectSome();
    
    // Test plot owner retrieval
    response = chain.callReadOnlyFn(
      'harvest-pro',
      'get-plot-owner',
      [types.ascii("PLOT-001")],
      deployer.address
    );
    response.result.expectOk().expectPrincipal(deployer.address);
  }
});
