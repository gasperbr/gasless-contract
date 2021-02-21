const BN = web3.utils.BN
const Agent = artifacts.require('Agent_')
const TestToken = artifacts.require('TestToken')

contract('Agent_', accounts => {
    
	const owner = accounts[0]
    const alice = accounts[1]
    const bob = accounts[1]
    
    const uniswapRouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";

    let agent
    let token0
    let token1

    mockSig = {
        v: "28",
        r: "0xa9fda421f0d8cc9e308895729d98845736175e93a042514f9dcf168bccd2bfde",
        s: "0x23cc6ba886c745d9afc3ba68f178c85c4e2a7fe67984ef3945643d5e59e79091"
    }
    
    before("Setup contract", async () => {
        token0 = await TestToken.new()
		token1 = await TestToken.new()
        agent = await Agent.new([token0.address, token1.address])
		token0.mint(alice, 1000)
    })

	it("Should instantiate contracts correctly", async() => {
        const aliceBalance = await token0.balanceOf(alice)
        const approval = await token0.allowance(agent.address, uniswapRouterAddress)
		assert.equal(aliceBalance.toString(10), 1000, "Alice did not receive mock tokens")
		assert.equal(approval.toString(10), 2**256-1, "Contract did not approve uniswap router for max value")
	})

    it("Should be able to claim tokens", async() => {

        const allowFor = 1000
        const claim = 100

        await token0.permit(alice, agent.address, allowFor, 1e15, mockSig.v, mockSig.r, mockSig.s)
        const allowance = await token0.allowance(alice, agent.address);
        assert.equal(allowance.toString(10), allowFor, "alice did not approve token spending")

        await agent._claimTokens(token0.address, alice, 0, claim, 0, 1e15, mockSig.v, mockSig.r, mockSig.s)
        const agentBalance = await token0.balanceOf(agent.address)
        assert.equal(agentBalance.toString(10), claim, "Agent didn't claim tokens")
	})

    it("Should have working helper functions", async() => {
        
        
        const ownerTokenBalanceOld = await token0.balanceOf(owner)
        await token0.mint(agent.address, 1000)
        const agentBalanceToken0 = await token0.balanceOf(agent.address)
        const expected0 = (ownerTokenBalanceOld.add(agentBalanceToken0)).toString(10)
        await agent.withdrawToken(token0.address)
        const ownerTokenBalance = await token0.balanceOf(owner)
        assert.equal(ownerTokenBalance.toString(10), expected0.toString(10), "Owner did not get any tokens")

        await agent.sendTransaction({from: owner,value: 1e18})
        
        const aliceBalanceOld = await web3.eth.getBalance(alice)
        const expected1 = (new BN(aliceBalanceOld)).add(new BN(1000))
        await agent._sendETHToReceiver(alice, 1000)
        const aliceBalance = await web3.eth.getBalance(alice)
        assert.equal(aliceBalance.toString(10), expected1.toString(10), "Ether was not sent to alice")
        
        const bobBalance0Old = await web3.eth.getBalance(bob)
        await agent._sendETHMinusFee(bob, 1000, 50000, {gas: 50000})
        const bobBalance0 = await web3.eth.getBalance(bob)
        assert.equal(bobBalance0, bobBalance0Old, "Contract wrongly sent ether")

        const sending = 1000000000000000;
        const bobBalance1Old = await web3.eth.getBalance(bob)
        await agent._sendETHMinusFee(bob, sending, 50000, {gas: 50000})
        const bobBalance1New = await web3.eth.getBalance(bob)
        assert.notEqual((new BN(bobBalance1Old)).add(new BN(sending)).sub(new BN(bobBalance1New)).toString(10), 0, "Contract didn't take a fee")
        assert.notEqual(bobBalance1Old, bobBalance1New, "Bob wasn't sent any ether")
    })

});
