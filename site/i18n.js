(function () {
  var D = {
    fr: {
      title: "BillPay Hub : maquette", nav_impact: "Impact", nav_ask: "Demander", nav_vote: "Tribunal", nav_council: "Conseil", nav_lots: "Lots", nav_rule: "Règle d'or",
      connect: "Connecter wallet", balance: "Solde disponible du solidarityWallet",
      next: "Prochaine distribution dans 07:42:10 · 126 familles aidées",
      ask_h: "Espace Demandeurs", ph_supplier: "Fournisseur (ex. électricité)", ph_amount: "Montant (€)",
      u1: "Urgence : coupure imminente", u2: "Urgence : élevée", u3: "Normale",
      ph_desc: "Décrivez votre situation (saisie manuelle, collage désactivé)",
      privacy: "Vos données privées sont masquées avant publication. Un contrôle IA est effectué.",
      send: "Envoyer ma demande", vote_h: "Tribunal Solidaire",
      c1_t: "Facture d'électricité", c1_tag: "Urgent", c1_d: "Montant : 182 € · Fournisseur : électricité · Dossier #A91F", c1_v: "Validateurs 3 / 5",
      c2_t: "Chauffage", c2_tag: "Élevée", c2_d: "Montant : 240 € · Fournisseur : gaz · Dossier #B22C", c2_v: "Validateurs 5 / 5 · Conseil 3 / 5",
      yes: "OUI 👍", no: "NON 👎", co_h: "Conseil du mois",
      co1: "3 pionniers", co1m: "Tirés au sort", co2: "Meilleur influenceur", co2m: "Vote plateforme",
      co3: "Contributeur X · Facebook · TikTok", co3m: "Classement du mois", co4: "Meilleur trader", co4m: "Classement on-chain",
      co5: "Wallet la plus fournie", co5m: "Moyenne du mois", co6: "Siège élu", co6m: "Vote sur le site", co6b: "Voter",
      lots_h: "Lots communautaires",
      lots_intro: "Les lots font entrer la communauté au capital du projet, dès le départ :",
      lots_l1: "Au lancement : 100 lots pionniers à 10 USDC.",
      lots_l2: "Ensuite, des séries de 50 USDC pour 100 USDC de BILL au prix du marché, qui n'ouvrent que lorsque le prix atteint x10 du prix de lancement.",
      lots_l3: "Cliff de 45 jours, puis déblocage linéaire sur 30 jours.",
      lots_l4: "Un lot par wallet.",
      s1: "Série 1", s1sold: "41 / 90 lots vendus",
      s1d: "Prix : 50 $ · Valeur : 100 USDC en BILL · Cliff 45 j puis déblocage linéaire sur 30 j · 1 lot par wallet",
      buy: "Acheter un lot", claim: "Claim",
      rule_h: "Règle d'or",
      rule_p: "Une contribution solidaire de 10 % sur chaque trade finance l'aide directe. Ce n'est pas une taxe : c'est un geste de la communauté, transparent et vérifiable sur la chaîne.",
      foot: "Maquette statique, aucune donnée réelle · Contribution solidaire de 10 % sur chaque trade"
    },
    en: {
      title: "BillPay Hub: mockup", nav_impact: "Impact", nav_ask: "Request", nav_vote: "Court", nav_council: "Council", nav_lots: "Lots", nav_rule: "Golden rule",
      connect: "Connect wallet", balance: "Available solidarityWallet balance",
      next: "Next distribution in 07:42:10 · 126 families helped",
      ask_h: "Requesters space", ph_supplier: "Provider (e.g. electricity)", ph_amount: "Amount (€)",
      u1: "Urgent: imminent cut-off", u2: "Urgent: high", u3: "Normal",
      ph_desc: "Describe your situation (manual typing, paste disabled)",
      privacy: "Your private data is masked before publication. An AI check is performed.",
      send: "Submit my request", vote_h: "Solidarity Vote Arena",
      c1_t: "Electricity bill", c1_tag: "Urgent", c1_d: "Amount: 182 € · Provider: electricity · Case #A91F", c1_v: "Validators 3 / 5",
      c2_t: "Heating", c2_tag: "High", c2_d: "Amount: 240 € · Provider: gas · Case #B22C", c2_v: "Validators 5 / 5 · Council 3 / 5",
      yes: "YES 👍", no: "NO 👎", co_h: "Council of the month",
      co1: "3 pioneers", co1m: "Drawn by lot", co2: "Top influencer", co2m: "Platform vote",
      co3: "X · Facebook · TikTok contributor", co3m: "Monthly ranking", co4: "Top trader", co4m: "On-chain ranking",
      co5: "Top wallet", co5m: "Monthly average", co6: "Elected seat", co6m: "Vote on the site", co6b: "Vote",
      lots_h: "Community lots",
      lots_intro: "Lots bring the community into the project from day one:",
      lots_l1: "At launch: 100 pioneer lots at 10 USDC.",
      lots_l2: "Later, series of 50 USDC for 100 USDC of BILL at market price, opening only when the price reaches x10 of the launch price.",
      lots_l3: "45-day cliff, then 30-day linear vesting.",
      lots_l4: "One lot per wallet.",
      s1: "Series 1", s1sold: "41 / 90 lots sold",
      s1d: "Price: $50 · Value: 100 USDC in BILL · 45-day cliff then 30-day linear vesting · 1 lot per wallet",
      buy: "Buy a lot", claim: "Claim",
      rule_h: "Golden rule",
      rule_p: "A 10% solidarity contribution on every trade funds direct aid. It is not a tax: it is a community gesture, transparent and verifiable on-chain.",
      foot: "Static mockup, no real data · 10% solidarity contribution on every trade"
    },
    ru: {
      title: "BillPay Hub: макет", nav_impact: "Влияние", nav_ask: "Заявка", nav_vote: "Суд", nav_council: "Совет", nav_lots: "Лоты", nav_rule: "Золотое правило",
      connect: "Подключить кошелёк", balance: "Доступный баланс solidarityWallet",
      next: "Следующая выплата через 07:42:10 · помощь получили 126 семей",
      ask_h: "Пространство заявителей", ph_supplier: "Поставщик (напр. электричество)", ph_amount: "Сумма (€)",
      u1: "Срочно: отключение вот-вот", u2: "Срочно: высокая", u3: "Обычная",
      ph_desc: "Опишите вашу ситуацию (только ручной ввод, вставка отключена)",
      privacy: "Ваши личные данные скрываются перед публикацией. Выполняется проверка ИИ.",
      send: "Отправить заявку", vote_h: "Арена голосования (Солидарный трибунал)",
      c1_t: "Счёт за электричество", c1_tag: "Срочно", c1_d: "Сумма: 182 € · Поставщик: электричество · Дело #A91F", c1_v: "Валидаторы 3 / 5",
      c2_t: "Отопление", c2_tag: "Высокая", c2_d: "Сумма: 240 € · Поставщик: газ · Дело #B22C", c2_v: "Валидаторы 5 / 5 · Совет 3 / 5",
      yes: "ДА 👍", no: "НЕТ 👎", co_h: "Совет месяца",
      co1: "3 пионера", co1m: "По жребию", co2: "Лучший инфлюенсер", co2m: "Голосование платформы",
      co3: "Участник X · Facebook · TikTok", co3m: "Рейтинг месяца", co4: "Лучший трейдер", co4m: "Рейтинг в блокчейне",
      co5: "Самый крупный кошелёк", co5m: "Среднее за месяц", co6: "Выборное место", co6m: "Голосование на сайте", co6b: "Голосовать",
      lots_h: "Лоты сообщества",
      lots_intro: "Лоты вводят сообщество в проект с самого начала:",
      lots_l1: "На старте: 100 пионерских лотов по 10 USDC.",
      lots_l2: "Позже серии по 50 USDC за 100 USDC в BILL по рыночной цене; они открываются только когда цена достигает x10 от стартовой.",
      lots_l3: "Клифф 45 дней, затем линейная разблокировка в течение 30 дней.",
      lots_l4: "Один лот на кошелёк.",
      s1: "Серия 1", s1sold: "41 / 90 лотов продано",
      s1d: "Цена: 50 $ · Стоимость: 100 USDC в BILL · Клифф 45 дн., затем линейная разблокировка 30 дн. · 1 лот на кошелёк",
      buy: "Купить лот", claim: "Claim",
      rule_h: "Золотое правило",
      rule_p: "Солидарный взнос 10 % с каждой сделки финансирует прямую помощь. Это не налог: это жест сообщества, прозрачный и проверяемый в блокчейне.",
      foot: "Статический макет, реальных данных нет · Солидарный взнос 10 % с каждой сделки"
    }
  };

  function apply(lang) {
    var d = D[lang] || D.fr;
    document.documentElement.lang = lang;
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      var k = el.getAttribute("data-i18n");
      if (d[k] !== undefined) el.textContent = d[k];
    });
    document.querySelectorAll("[data-i18n-ph]").forEach(function (el) {
      var k = el.getAttribute("data-i18n-ph");
      if (d[k] !== undefined) el.setAttribute("placeholder", d[k]);
    });
    var sel = document.getElementById("lang");
    if (sel) sel.value = lang;
  }

  var saved = null;
  try { saved = localStorage.getItem("lang"); } catch (e) {}
  var lang = D[saved] ? saved : "fr";
  apply(lang);
  var sel = document.getElementById("lang");
  if (sel) sel.addEventListener("change", function () {
    try { localStorage.setItem("lang", sel.value); } catch (e) {}
    apply(sel.value);
  });
})();
