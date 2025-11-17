export const servicePlatforms = () => {
  const items = [
    {
      name: 'Facebook',
      value: 'facebook',
      img: 'images/companies/facebook.png',
    },
    {
      name: 'Instagram',
      value: 'instagram',
      img: 'images/companies/instagram.png',
    },
    {
      name: 'Twitter',
      value: 'twitter',
      img: 'images/companies/twitter.png',
    },
    {
      name: 'TikTok',
      value: 'tiktok',
      img: 'images/companies/tiktok.png',
    },
    { name: 'Luno', value: 'luno', img: 'images/companies/luno.png' },
    {
      name: 'Boost',
      value: 'boost',
      img: 'images/companies/boost_app_malaysia.png',
    },
    {
      name: `Touch 'n Go`,
      value: 'touch_n_go',
      img: 'images/companies/touch_n_go_e_wallet.png',
    },
    {
      name: 'GrabPay',
      value: 'grabpay',
      img: 'images/companies/grab_taxi_food_delivery.png',
    },
    {
      name: 'AEON Wallet',
      value: 'aeon wallet',
      img: '',
    },
    {
      name: 'BigPay',
      value: 'bigpay',
      img: '',
    },
    {
      name: 'WeChat Pay',
      value: 'wechat_pay',
      img: 'images/companies/we_chat.png',
    },
    {
      name: 'Lazada',
      value: 'lazada',
      img: 'images/companies/lazada.png',
    },
    {
      name: 'ShopeePay',
      value: 'shopeepay',
      img: 'images/companies/shopee_my.png',
    },
    { name: 'Wahed', value: 'wahed', img: 'images/companies/wahed.png' },
    { name: 'Raiz', value: 'raiz', img: 'images/companies/raiz_invest.png' },
    {
      name: 'PublicGold',
      value: 'publicgold',
      img: '',
    },
    {
      name: 'StashAway',
      value: 'stashaway',
      img: 'images/companies/stash_away.png',
    },
    { name: 'NFTs', value: 'nfts', img: '' },
    {
      name: 'Mobile Legends',
      value: 'mobile_legends',
      img: '',
    },
    {
      name: 'Spotify',
      value: 'spotify',
      img: 'images/companies/spotify.png',
    },
    {
      name: 'YouTube',
      value: 'youtube',
      img: 'images/companies/youtube.png',
    },
    {
      name: 'iCloud',
      value: 'icloud',
      img: '',
    },
    {
      name: 'Microsoft Azure',
      value: 'microsoft_azure',
      img: '',
    },
    {
      name: 'Google Cloud',
      value: 'google_cloud',
      img: '',
    },
    {
      name: 'Dropbox',
      value: 'dropbox',
      img: '',
    },
    { name: 'Box', value: 'box', img: '' },
    { name: 'AWS', value: 'aws', img: '' },
    {
      name: 'Alibaba Cloud',
      value: 'alibaba_cloud',
      img: 'images/companies/alibaba_b2b_marketplace.png',
    },
    {
      name: 'OneDrive',
      value: 'onedrive',
      img: '',
    },
    {
      name: 'WordPress',
      value: 'wordpress',
      img: 'images/companies/wordpress.png',
    },
    {
      name: 'Blogspot',
      value: 'blogspot',
      img: 'images/companies/blogger.png',
    },
  ];

  return items;
};

export const institutions = () => {
  const items = [
    {
      name: 'HSBC Bank',
      value: 'hsbc_bank',
      img: '',
    },
    {
      name: 'Maybank',
      value: 'maybank',
      img: '',
    },
    {
      name: 'Standard Chartered Bank',
      value: 'standart_chartered_bank',
      img: '',
    },
    {
      name: 'AiAtakaful',
      value: 'aia_takaful',
      img: '',
    },
  ];

  return items;
};

export const loanCategories = () => {
  const items = [
    {
      name: 'Credit Card',
      value: 'credit_card',
      img: '',
    },
    {
      name: 'Hire Purchase',
      value: 'hire_purchase',
      img: '',
    },
  ];

  return items;
};

export const maritalStatus = () => {
  const items = [
    { name: 'Single', value: 'single' },
    { name: 'Married', value: 'married' },
    { name: 'Widowed', value: 'widowed' },
    { name: 'Divorced', value: 'divorced' },
  ];

  return items;
};

export const servicePlatformAccountTypes = () => {
  const items = [
    {
      name: 'Non-Subscription',
      opName: 'No',
      value: 'non_subscription',
      translationKey: 'no',
    },
    {
      name: 'Subscription',
      opName: 'Yes',
      value: 'subscription',
      translationKey: 'yes',
    },
  ];

  return items;
};

export const physicalAccountTypes = () => {
  const items = [
    { name: 'Asset', value: 'asset' },
    { name: 'Loan', value: 'loan' },
    { name: 'Protection', value: 'protection' },
  ];

  return items;
};

export const servicePlatformFrequencies = () => {
  const items = [
    { name: 'N/A', value: 'n_a' },
    // { name: 'Weekly', value: 'weekly' },
    { name: 'Monthly', value: 'monthly' },
    { name: 'Yearly', value: 'yearly' },
  ];

  return items;
};

export const declaredValues = () => {
  const items = [
    { name: 'N/A', value: 'n_a' },
    { name: 'RM 1000 - RM 5000', value: '1k_5k' },
    { name: 'RM 5001 - RM 10,000', value: '5k_10k' },
    { name: 'RM 10,001 - RM 15,000', value: '10k_15k' },
    { name: 'RM 15,001 - RM 50,000', value: '15k_50k' },
    { name: 'RM 50,001 - RM 100,000', value: '50k_100k' },
    { name: 'RM 100,001 - RM 250,000', value: '100k_250k' },
    { name: 'More than RM 250,001', value: 'more_than_250k' },
  ];

  return items;
};

export const instructionsAfterDeath = (religion) => {
  const options = [
    {
      name: 'Transfer as gift',
      opName: 'Pass this account to be used by my beneficiary',
      value: 'transfer_as_gift',
      theme: 'blue',
      translationKey: 'pass_this_account_',
      translationKey1: 'transfer_as_gift',
      shortName: 'Gift',
    },
    {
      name: 'Terminate',
      opName: 'Account to be terminated',
      value: 'terminate',
      theme: 'orange',
      translationKey: 'account_to_terminated',
      translationKey1: 'terminate',
      shortName: 'Terminate',
    },
    {
      name: 'Settle Debts',
      opName: 'Account to be Settle Debts',
      value: 'settle',
      theme: 'orange',
      translationKey: 'account_to_settle_debts',
      translationKey1: 'settle_debts',
      shortName: 'Settle Debts',
    },
  ];

  if (['islam', null, undefined].includes(religion)) {
    options.unshift({
      name: 'Faraid',
      opName:
        'My beneficiary to liquidate the account and proceeds to be distributed as per Faraid',
      value: 'faraid',
      theme: 'green',
      translationKey: 'beneficiary_liquidate_account',
      translationKey1: 'faraid',
      shortName: 'Faraid',
    });
  }

  return options;
};

export const addNew = () => {
  const options = [
    { name: 'Please select...', value: '' },
    { name: 'Add New', value: 'add_new' },
  ];

  return options;
};

export const relationships = () => {
  const options = [
    { name: 'Friend', value: 'friend' },
    { name: 'Partner', value: 'partner' },
    { name: 'Sibling', value: 'sibling' },
    { name: 'Parent', value: 'parent' },
    { name: 'Child', value: 'child' },
    { name: 'Colleague', value: 'colleague' },
    { name: 'Acquaintance', value: 'acquaintance' },
    { name: 'Spouse', value: 'spouse' },
    { name: 'Relative', value: 'relative' },
    { name: 'Others', value: 'others' },
  ];

  return options;
};

export const executorRelationships = () => {
  const options = [
    { name: 'Husband', value: 'husband' },
    { name: 'Wife', value: 'wife' },
    { name: 'Father', value: 'father' },
    { name: 'Mother', value: 'mother' },
    { name: 'Child', value: 'child' },
    { name: 'Others', value: 'others' },
  ];

  return options;
};

export const executorDeathCause = () => {
  const options = [
    { name: 'Natural Cause', value: 'natural' },
    { name: 'Accident', value: 'accident' },
  ];

  return options;
};

export const ethnicities = () => {
  const options = [
    { name: 'Malay', value: 'malay' },
    { name: 'Chinese', value: 'chinese' },
    { name: 'Indian', value: 'indian' },
    { name: 'Others', value: 'others' },
  ];

  return options;
};

export const beneficiaryTypes = () => {
  const options = [
    { name: 'Co-Sampul', value: 'co_sampul' },
    { name: 'Future owner', value: 'future_owner' },
    { name: 'Guardian', value: 'guardian' },
  ];

  return options;
};

export const belovedLevel = () => {
  const options = [
    {
      name: 'Primary',
      value: 'primary',
      translationKey: 'primary',
      translationKey2: 'primary_co_sampul',
    },
    {
      name: 'Secondary',
      value: 'secondary',
      translationKey: 'secondary',
      translationKey2: 'secondary_co_sampul',
    },
    { name: 'Others', value: 'others', translationKey: 'others' },
  ];

  return options;
};

export const religions = () => {
  const options = [
    { name: 'Islam', value: 'islam' },
    { name: 'Christianity', value: 'christianity' },
    { name: 'Buddhism', value: 'buddhism' },
    { name: 'Hinduism', value: 'hinduism' },
    { name: 'Sikhism', value: 'sikhism' },
    { name: 'Confucianism', value: 'confucianism' },
    { name: 'Taoism', value: 'taoism' },
    { name: 'Others', value: 'others' },
  ];

  return options;
};

export const preferablyCommunications = () => {
  const options = [
    { name: 'Email', value: 'email' },
    { name: 'WhatsApp', value: 'whatsapp' },
  ];

  return options;
};

export const countries = () => {
  const options = [
    { name: 'Malaysia', value: 'malaysia', flag_icon: 'images/MY.png' },
    { name: 'Singapore', value: 'singapore' },
    { name: 'Brunie', value: 'brunie' },
    { name: 'Indonesia', value: 'indonesia' },
  ];

  return options;
};

export const careerCategories = () => {
  const options = [
    { name: 'Design', value: 'design' },
    { name: 'Software Development', value: 'software_development' },
    { name: 'Customer Success', value: 'customer_success' },
  ];

  return options;
};

export const blogCategories = () => {
  const options = [
    { name: 'Wasiat', value: 'wasiat' },
    { name: 'Will', value: 'will' },
    { name: 'Muamalat', value: 'muamalat' },
    { name: 'Harta Pusaka', value: 'harta_pusaka' },
  ];

  return options;
};

export const charityBodies = () => {
  const options = [
    { name: 'Body A', value: 'body_a' },
    { name: 'Body B', value: 'body_b' },
    { name: 'Body C', value: 'body_c' },
  ];

  return options;
};

export const waqfBodies = () => {
  const options = [
    { name: 'Body A', value: 'body_a' },
    { name: 'Body B', value: 'body_b' },
    { name: 'Body C', value: 'body_c' },
  ];

  return options;
};

export const belovedInviteStatus = () => {
  const options = [
    { name: 'Pending', value: 'pending', translationKey: 'pending' },
    { name: 'Accepted', value: 'accepted', translationKey: 'accepted' },
    { name: 'Rejected', value: 'rejected', translationKey: 'rejected' },
  ];

  return options;
};

export const userRoles = () => {
  const options = [
    { name: 'User', value: 'user' },
    { name: 'Admin', value: 'admin' },
    { name: 'Partner', value: 'partner' },
  ];

  return options;
};

export const trueFalse = () => {
  const options = [
    { name: 'Yes', value: true },
    { name: 'No', value: false },
  ];

  return options;
};

export const bodiesCategory = () => {
  const options = [
    { name: 'Social Media', value: 'social_media' },
    { name: 'Photos and Memories', value: 'photos_and_memories' },
    { name: 'Content and Channel', value: 'content_and_channel' },
    { name: 'Workplace', value: 'workplace' },
    { name: 'Investment', value: 'investment' },
    { name: 'Crypto', value: 'crypto' },
    { name: 'E-Wallet & Saving', value: 'e_wallet_saving' },
    {
      name: 'E-Wallet & Saving, Investment',
      value: 'e_wallet_saving_investment',
    },
    {
      name: 'E-Wallet & Saving, Social Media',
      value: 'e_wallet_saving_social_media',
    },
    {
      name: 'Digital Domain',
      value: 'digital_domain',
    },
    { name: 'Marketplace & Rewards', value: 'marketplace_rewards' },
    { name: 'Sadaqah, Waqaf, Zakat', value: 'sadaqah_waqaf_zakat' },
    { name: 'Personal Note Taking', value: 'personal_note_taking' },
    { name: 'Entertainment', value: 'entertainment' },
    { name: 'NFT', value: 'nft' },
    { name: 'Waqaf', value: 'waqaf' },
    { name: 'Finance', value: 'finance' },
    { name: 'Productivities', value: 'productivities' },
    { name: 'Tools & Business', value: 'tools_and_business' },
    { name: 'Restaurants & delivery', value: 'restaurants_and_delivery' },
    { name: 'Shopping', value: 'shopping' },
    { name: 'Travel', value: 'travel' },
    { name: 'Physical Assets', value: 'physical_assets' },
  ];

  return options;
};

export const systemLanguages = () => {
  const options = [
    { name: 'Malay', value: 'malay', langCode: 'bm' },
    { name: 'English', value: 'english', langCode: 'en' },
  ];

  return options;
};

// PENDING DB!!!
export const genders = () => {
  const options = [
    { name: 'Male', value: 'male' },
    { name: 'Female', value: 'female' },
  ];

  return options;
};

export const residentStatus = () => {
  const options = [
    { name: 'Resident', value: 'resident' },
    { name: 'Non-resident', value: 'non_resident' },
  ];

  return options;
};

export const estimatedNetWorths = () => {
  const options = [
    { name: 'below RM50,000', value: 'below_rm_50k' },
    { name: 'RM50,001 to RM100,000', value: 'rm_50k_to_100k' },
    { name: 'RM100,001 to RM150,000', value: 'rm_100k_to_150k' },
    { name: 'RM150,001 to RM200,000', value: 'rm_150k_to_200k' },
    { name: 'RM200,001 to RM300,000', value: 'rm_200k_to_300k' },
    { name: 'more than RM300,000', value: 'above_rm_300k' },
  ];

  return options;
};

export const pepTypes = () => {
  const options = [
    {
      name: 'Head of Government/ State Politician',
      value: 'head_of_state_or_state_politician',
    },
    {
      name: 'Royal Family Friend/ Business Associates',
      value: 'royal_family_friend_business_associates',
    },
    {
      name: 'Family member of Politically Exposed Judicial, Army or Police Official',
      value: 'family_member_of_pep_judicial_army_police',
    },
    {
      name: 'Person (PEP)',
      value: 'person_pep',
    },
    {
      name: 'Senior Management of Government Linked Company',
      value: 'senior_management_government_linked_company',
    },
    {
      name: 'Not Applicable',
      value: 'not_applicable',
    },
    {
      name: 'Other',
      value: 'other',
    },
  ];

  return options;
};

export const donationCategories = () => {
  const options = [
    { name: 'Mosque', value: 'mosque' },
    { name: 'School', value: 'school' },
    { name: 'Hospital', value: 'hospital' },
    { name: 'Qurban', value: 'qurban' },
    { name: 'Other', value: 'other' },
  ];

  return options;
};

export const currencies = () => {
  const options = [
    { name: '$', fullName: 'US Dollar', value: 'USD' },
    { name: '€', fullName: 'Euro', value: 'EUR' },
    { name: '£', fullName: 'British Pound', value: 'GBP' },
    { name: '¥', fullName: 'Japanese Yen', value: 'JPY' },
    { name: '$', fullName: 'Canadian Dollar', value: 'CAD' },
    { name: '$', fullName: 'Australian Dollar', value: 'AUD' },
    { name: 'Fr', fullName: 'Swiss Franc', value: 'CHF' },
    { name: '¥', fullName: 'Chinese Yuan', value: 'CNY' },
    { name: '₹', fullName: 'Indian Rupee', value: 'INR' },
    { name: 'R$', fullName: 'Brazilian Real', value: 'BRL' },
    { name: 'RM', fullName: 'Malaysian Ringgit', value: 'MYR' },
  ];

  return options;
};

export const banks = () => {
  const options = [
    { name: 'Affin Bank Berhad', value: 'affin_bank' },
    { name: 'Alliance Bank Malaysia Berhad', value: 'alliance_bank' },
    { name: 'AmBank (M) Berhad', value: 'ambank' },
    { name: 'CIMB Bank Berhad', value: 'cimb_bank' },
    { name: 'Hong Leong Bank Berhad', value: 'hong_leong_bank' },
    { name: 'Malayan Banking Berhad (Maybank)', value: 'maybank' },
    { name: 'Public Bank Berhad', value: 'public_bank' },
    { name: 'RHB Bank Berhad', value: 'rhb_bank' },
    { name: 'Bank Islam Malaysia Berhad', value: 'bank_islam' },
    { name: 'OCBC Bank (Malaysia) Berhad', value: 'ocbc_bank_malaysia' },
    { name: 'HSBC Bank Malaysia Berhad', value: 'hsbc_bank_malaysia' },
    { name: 'United Overseas Bank (Malaysia) Bhd', value: 'uob_malaysia' },
    {
      name: 'Standard Chartered Bank Malaysia Berhad',
      value: 'standard_chartered_malaysia',
    },
    { name: 'Bank Muamalat Malaysia Berhad', value: 'bank_muamalat' },
  ];

  return options;
};

export const donationDurations = () => {
  const options = [
    { name: 'Yearly', value: 'yearly' },
    { name: 'Monthly', value: 'monthly' },
    { name: 'Quarterly', value: 'quarterly' },
    { name: 'One-Time', value: 'one_time' },
    { name: 'Weekly', value: 'weekly' },
  ];

  return options;
};

export const sourceOfWealth = () => {
  const options = [
    { name: 'Salary', value: 'salary' },
    { name: 'Investment Account', value: 'investment_account' },
    { name: 'Savings', value: 'savings' },
    { name: 'Inheritance', value: 'inheritance' },
    { name: 'Sale of Property/Asset', value: 'sale_of_property_asset' },
    { name: 'Retirement Account (EPF/RPS)', value: 'retirement_account' },
    { name: 'Other', value: 'other' },
  ];

  return options;
};

export const paymentMethods = () => {
  const options = [
    {
      name: 'Bank Transfer',
      value: 'bank_transfer',
      sublabel: '(Manual Transfer)',
      enable: true,
    },
    {
      name: 'FPX',
      value: 'fpx',
      sublabel: '(Online Banking)',
      enable: false,
    },
    {
      name: 'Card',
      value: 'card',
      sublabel: '(Credit/Debit)',
      enable: false,
    },
    {
      name: 'E-Wallet',
      value: 'e_wallet',
      sublabel: `(Touch 'n Go, GrabPay)`,
      enable: false,
    },
  ];

  return options;
};
