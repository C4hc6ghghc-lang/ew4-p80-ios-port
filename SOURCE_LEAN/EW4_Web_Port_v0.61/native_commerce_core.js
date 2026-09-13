'use strict';

/*
 * European War 4 native commerce formulas recovered from
 * libeuropean-war-4.so v1.4.42 (x86_64/arm64 cross-check).
 * Keep this module DOM-free so the reverse-engineered rules are testable.
 */
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4Commerce=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const MARKET_MONEY=[10,50,10,50];
  const MARKET_GOODS=[2,10,50,250];

  function businessStars(value){
    const n=Number(value);
    return Number.isFinite(n)?Math.max(0,Math.min(5,Math.trunc(n))):0;
  }

  /* native helper @ x86_64 0x584a0:
     1.0 + (5 - business) * 0.4, fallback 3.0. */
  function tradeRate(business){
    return 1+(5-businessStars(business))*0.4;
  }

  function marketResource(index){return Number(index)<=1?'industry':'food'}

  /* Native buy buttons: money -> industry/food.
     Cost is truncated after multiplying the fixed money table by tradeRate. */
  function marketBuyQuote(index,business){
    index=Number(index);
    if(!Number.isInteger(index)||index<0||index>3)return null;
    return {
      direction:'buy',index,rate:tradeRate(business),
      payResource:'money',pay:Math.trunc(MARKET_MONEY[index]*tradeRate(business)),
      receiveResource:marketResource(index),receive:MARKET_GOODS[index]
    };
  }

  /* Native sell buttons: industry/food -> money.
     Required goods are multiplied by tradeRate; money payout stays fixed. */
  function marketSellQuote(index,business){
    index=Number(index);
    if(!Number.isInteger(index)||index<0||index>3)return null;
    return {
      direction:'sell',index,rate:tradeRate(business),
      payResource:marketResource(index),pay:Math.trunc(MARKET_GOODS[index]*tradeRate(business)),
      receiveResource:'money',receive:MARKET_MONEY[index]
    };
  }

  function canApplyQuote(resources,quote){
    return !!(resources&&quote&&Number(resources[quote.payResource]||0)>=quote.pay);
  }

  function applyQuote(resources,quote){
    if(!canApplyQuote(resources,quote))return false;
    resources[quote.payResource]=Number(resources[quote.payResource]||0)-quote.pay;
    resources[quote.receiveResource]=Number(resources[quote.receiveResource]||0)+quote.receive;
    return true;
  }

  /* Native shop pricing @ x86_64 0x5b320:
     commerce stars grant 4% discount per star, 0..20%, integer truncation. */
  function shopDiscountPercent(business){return businessStars(business)*4}
  function shopBuyPrice(basePrice,business){
    const base=Math.max(0,Math.trunc(Number(basePrice)||0));
    const pct=shopDiscountPercent(business);
    return base-Math.trunc(base*pct/100);
  }

  return Object.freeze({
    MARKET_MONEY:Object.freeze(MARKET_MONEY.slice()),
    MARKET_GOODS:Object.freeze(MARKET_GOODS.slice()),
    businessStars,tradeRate,marketResource,marketBuyQuote,marketSellQuote,
    canApplyQuote,applyQuote,shopDiscountPercent,shopBuyPrice
  });
});
