import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can register new asset",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const asset_id = 1;
    const initial_state = 100;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        'token-sync',
        'register-asset',
        [types.uint(asset_id), types.uint(initial_state)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result, '(ok true)');
  },
});

Clarinet.test({
  name: "Ensure can request and approve sync",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    const asset_id = 1;
    const initial_state = 100;
    const new_state = 200;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        'token-sync',
        'register-asset',
        [types.uint(asset_id), types.uint(initial_state)],
        deployer.address
      ),
      Tx.contractCall(
        'token-sync',
        'request-sync',
        [types.uint(asset_id), types.uint(new_state)],
        user1.address
      ),
      Tx.contractCall(
        'token-sync',
        'approve-sync',
        [types.uint(asset_id), types.principal(user1.address)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 3);
    assertEquals(block.receipts[0].result, '(ok true)');
    assertEquals(block.receipts[1].result, '(ok true)');
    assertEquals(block.receipts[2].result, '(ok true)');
  },
});
