'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "4835042e56cfe65d257fb258ce205410",
".git/config": "6e0c4ad2e4948a46809d65930e290eb7",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "fd247747a213284dfe5d06342a2cd299",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "d294af91915b7b62a7d45c27e540c4c2",
".git/logs/refs/heads/main": "97d7cbb8679d67f3e31e0b9f2931965c",
".git/logs/refs/remotes/origin/gh-pages": "05416ba43bfc7638174ff4ee1fbf5253",
".git/objects/01/ce9b5f9dbd4d5512b62599dde49d0aa6fa9159": "3e234ad851335bca24ad252320c4e6b0",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/0d/d0bacb9c3be0c272ec51a852f6aab32badf99b": "727f912c203f675b63abbbcdfc4cc0d6",
".git/objects/0f/e34d2c4ab2fbf1f578ae4bc717994e4e4fbaf5": "fd8394c1b6f12ff816202a4b9e3a1604",
".git/objects/10/9e09162ca13a58688826bdba02799a2807377e": "1cbece680724604d8d9a5827bdb62a2d",
".git/objects/22/5744bd6947df637fa2f5dbcc5e7c0dea0a6aa1": "9a92957b4a8b60d7f510b1a0baaae628",
".git/objects/27/56b569742b162b4941b2ee8e1a5bc8d955e6b7": "db73fc809cd8825dbee0df1bd0ee2837",
".git/objects/29/00a47aeef97c1525ed6f65a213c0062d621036": "63a026fcc9ecba45bd5fbe72d5e06a98",
".git/objects/29/cda19436f0d1d6b75d05b2c781108d0d6bff82": "87905fbf8dda4ccb7e68cdc9fc1cc69b",
".git/objects/3a/0668c904b249899a698e92306b191001f8ae48": "2096f70be5b8394ca27906ec5121dabf",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3b/eb7890b45ca2875195243c4d7b8090b4f2549e": "7ad1148a6be26d6dc597bf1d110c6ccb",
".git/objects/3f/a1b454e4718e4cd3be2081f75a45a921d09690": "06984386e4c9faa357786b99b52da12c",
".git/objects/45/45b8eaf094b432e53b551486b4dbcd4586844d": "ae8553488dfce048a2bf9bf1333cda81",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/54/896156f4f584e3e0b6176ef5bb82046c8eefeb": "f54cbc306cb34dca4cec1f1302ab6ff8",
".git/objects/5b/7a431a459a3af4ad43f7e55061a95df84bb7bf": "0d6d6fbebe297033ebbdceab3398d2c5",
".git/objects/5c/a017893b2927c9a549a678278c883a97ef2a0d": "ae6097befff3fad1d76396cd065264d6",
".git/objects/5e/2f58b432c62353cbcf6958d622c8c949de7c32": "d3a2c6798f38d4d57d7fbcac22661a6c",
".git/objects/61/2498b2de4073dc1c7e3f143f12fd7210215413": "f021e5e0ef88a23ffe258f8541d17588",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/69/7612b856b42c7df2f6b11a751697ce3fb59ba5": "eb2c167bd5d2090211aac5d103a33a2d",
".git/objects/69/79cd0131f455eb29246b1a4b141c5110d3a94f": "99d79c1a1a8115e1e1528437fb120102",
".git/objects/6b/bdd375610bf7be41759e89779f35e95224d51f": "0c9c8f1ff20175c8230e60fcf1c4b56b",
".git/objects/6e/3d726ded0c329dba6fb8f1a2ee5e784a1671cc": "a09188045a052f3fe6021abb89d2c8bb",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/6f/e432e6774de513b1eca68c0bcad838b54ac68d": "c48cc59a4a0be73525d6ffaaad6ab285",
".git/objects/70/6b89226856a184964d4ef26acca4690f34feb3": "b47861a6de6336cfde49244ec049778b",
".git/objects/72/ada6baac9193047a04d1ef7fc6c08c19a0aad4": "515cf0496f523efb00e1cdbca48aebe4",
".git/objects/72/d2ac11e3a7e709db33c98612eb36324b65a1c5": "c79df3f24627348b03a122af4e1edf89",
".git/objects/75/42c6b0e9cdcf9c8e3f7da12ab5edf7415f9fad": "f31e0e5a82c78b71792ba19b15f96867",
".git/objects/79/1432048ab5751f8501e81c5c89c8e3bad079f0": "e7cb5a755032e3d6475a139ccbeb9916",
".git/objects/7b/90f222734e771beee19122e6051128a08a1766": "8e059fb255fb5b195780121f65e1911a",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/7c/c3597bd8503cb8eb3d673fc9a463459aa108a8": "c4e92d2f9a1ea9974a97df8c2161fbdc",
".git/objects/84/ffe9fb9c232367fb5c97259d34bc3c7e474c22": "55b4cbd52cc26d764bcf3084f6b597b7",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/89/3c2d4c82a46a3498c217be223cfb9a91b205ad": "dc137e41c79148f818bb4370a06df7c3",
".git/objects/8a/9481082a170363b8f9c6c78459795ccdcab3e8": "9ddd0b2635ab6e1cca4661f12e97aafa",
".git/objects/8e/21753cdb204192a414b235db41da6a8446c8b4": "1e467e19cabb5d3d38b8fe200c37479e",
".git/objects/90/fa64bf0fab4eb0125d62b0e218dddd765dc3c7": "3a940385dce05046f1e439e3ce5baca8",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/a1/8954b2ba84c39f8853c7d1a1017a13b6e767cc": "bdd46378b4ff8eddab56d01347716a73",
".git/objects/a4/f54d8c74090feff326e7572c65e4a5d2f4887b": "a45d52c5029f1febb8690de0c6635cc6",
".git/objects/a7/3f4b23dde68ce5a05ce4c658ccd690c7f707ec": "ee275830276a88bac752feff80ed6470",
".git/objects/a9/91f51138ffe059d588003dc7936aff059a0428": "b73a35563fa129bd884d8b5c53ee9231",
".git/objects/ad/2f90b78480aeb6608226d9db4ecbd3ec06aaeb": "4add97a99941aa0e9eed0f2173416ade",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/bc/7d993f94baf32ca11e5f5dc5412aac12a668a9": "d782f8a82d795ae96da7df117f4c51bd",
".git/objects/c3/944b8a86e8e765015d9f823da8321bc425b40f": "00f2a42df0979a2759e789cb2c87b344",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/ca/28c42816e1ba98b5202e9a751a7a71c42d96e6": "963cafb9d7043e8a4b08248318128b18",
".git/objects/cc/fab74c1f56c330985060e2247607eaedb3c7d7": "ad5b6117df489509af208438785f208b",
".git/objects/d0/b5615014f4f0a80a4bd2ac3a092f611620fb8c": "4511ad2717cd70eb06adbba99b02e671",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d5/23a120df0177b2544af8bd2b1c6e0f19a04830": "ac83ce2b8e5ea86bdd043d93f7e1623c",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/d9/982f617bad599951a76c8731e4bd5121ed17aa": "cc04dd47ec8967fa37f2524257983a74",
".git/objects/df/3f463aa80f6dc6b80ceb38b0c7ab0c5a15a72f": "50a950caa9b634701dd7744405262dfa",
".git/objects/e3/893d874f83726c7faee6b44a20e3f501a947cf": "018c2070207c5adf1a0677acd0bd09fc",
".git/objects/e4/98b7cc726d0dbfb882fe927200525e68916413": "27de7c3e8ae1ead9146ed668ab532999",
".git/objects/e7/dce87d7e29e2d79ad5da1c0c87cbb0e7c5205b": "1e21ff88ed59ac7870cd58b52ce408a8",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f6/cc06a0d471df5df1f35082b09b45fced798d05": "b3ed116bd3c82d600d635270058f4345",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/ff/1511c29463d7f470d5dd4e05d7929565c0262a": "787a203634589c2f5806268959b2b777",
".git/refs/heads/main": "0ba6a7eb68f11dd3914438c33c12fea1",
".git/refs/remotes/origin/gh-pages": "0ba6a7eb68f11dd3914438c33c12fea1",
"assets/AssetManifest.bin": "47c369882a3b0135ba32b81f1f76aea2",
"assets/AssetManifest.bin.json": "44a7eb83cea1d5c3e2cb0af0b4a01757",
"assets/assets/animations/box.json": "906dfbe2d69b0cab6d762cd4d0645151",
"assets/assets/animations/boy%2520with%2520jet%2520pack%2520loding%2520animation.json": "7408cb948dfaaedb7851393883f62599",
"assets/assets/animations/coinscomeanimation.json": "bbd4688fba8a5b8ff2534fe7387f3471",
"assets/assets/animations/Success.json": "ae3962d35e301e4f8452c31da454b0e8",
"assets/assets/animations/Trophy.json": "06363136e1a81639b8ae12789528088c",
"assets/assets/env": "d493d99b2904021b421a3ab8a960b42e",
"assets/assets/images/icon.png": "154e4ccb4aef61bb821c5ef60e537f1b",
"assets/assets/music/money-earn.mp3": "4bd5aaa4ce7851aa14f3b5f5dd65f598",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "ade49a1aafef8ab0aaebf3460749cfec",
"assets/NOTICES": "e5081ed9dc1f9284372f848f8bf1082f",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "d7d83bd9ee909f8a9b348f56ca7b68c6",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.css": "5a8d0222407e388155d7d1395a75d5b9",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.html": "16911fcc170c8af1c5457940bd0bf055",
"assets/packages/flutter_inappwebview_web/assets/web/web_support.js": "509ae636cfdd93e49b5a6eaf0f06d79f",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/packages/youtube_player_flutter/assets/speedometer.webp": "50448630e948b5b3998ae5a5d112622b",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "3f7806045c5259f85d499b1dfcc943d1",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "0f8685af2969654944bd48d6a616b33b",
"icons/Icon-192.png": "fc440ee5cb6378f1d6683d4428222c74",
"icons/Icon-512.png": "628612975b2cca14146a2ca69bfa0d78",
"icons/Icon-maskable-192.png": "fc440ee5cb6378f1d6683d4428222c74",
"icons/Icon-maskable-512.png": "628612975b2cca14146a2ca69bfa0d78",
"index.html": "c341e39bd2e47463b3b5c01dac63b2b2",
"/": "c341e39bd2e47463b3b5c01dac63b2b2",
"main.dart.js": "eb89efc9621cf78ecd7a5a510c3fa3d2",
"manifest.json": "58f762c0e1c729be8f9389e32e515a24",
"version.json": "fc9c2024a78ca0b7c61326519f17fd2f"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
