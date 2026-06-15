import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/repositories/community_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(ref.watch(firestoreProvider));
});

final communityPostsProvider = StreamProvider<List<CommunityPostEntity>>((ref) {
  return ref.watch(communityRepositoryProvider).watchPosts().map((posts) {
    // Gerçek gönderilerin altına mock gönderileri her zaman ekle
    return [...posts, ..._mockPosts];
  });
});

final postCommentsProvider =
    StreamProvider.family<List<CommentEntity>, String>((ref, postId) {
  return ref.watch(communityRepositoryProvider).watchComments(postId).map(
    (comments) {
      // Demo post yorumları
      if (comments.isEmpty) {
        return _mockComments.where((c) => c.postId == postId).toList();
      }
      return comments;
    },
  );
});

// ---------------------------------------------------------------------------
// DEMO / Mock veriler — Firestore henüz boşken gösterilir
// ---------------------------------------------------------------------------

final _now = DateTime.now();

final List<CommunityPostEntity> _mockPosts = [
  CommunityPostEntity(
    id: 'mock_1',
    authorId: 'demo_user_1',
    authorName: 'Ahmet Yılmaz',
    brand: 'Togg',
    title: 'Togg T10X ile İstanbul-Ankara yaptım 🚗⚡',
    content: 'Geçen hafta sonu Togg T10X ile ilk uzun yolculuğumu yaptım. '
        'Hendek ZES\'te 40 dk bekledim, kalan 2 duraklarda toplam 1 saat. '
        'Toplam maliyet yaklaşık 320₺ — benzinli arabamla kıyaslamak '
        'istemedim, çok utanırlardı 😄 Güzergahı önce EV Navigator ile '
        'planladım, hiç sürprizle karşılaşmadım.',
    photoUrls: const [],
    likeCount: 47,
    commentCount: 12,
    likedBy: const [],
    createdAt: _now.subtract(const Duration(hours: 3)),
  ),
  CommunityPostEntity(
    id: 'mock_2',
    authorId: 'demo_user_2',
    authorName: 'Selin Kaya',
    brand: 'Tesla',
    title: 'Model 3 batarya sağlığı — 80.000 km sonra',
    content: 'Model 3 Long Range\'im 80.000 km\'yi geride bıraktı. Batarya SOH '
        'hâlâ %91. Şarj alışkanlığı olarak hiç %100\'e kadar doldurmadım, '
        'genelde %80\'de bırakıyorum. DC fast charge kullanımını aylık '
        'en fazla 4-5 seferle sınırladım. Uygulamadaki batarya sağlığı '
        'grafiği gerçekten işe yarıyor, tavsiye ederim.',
    photoUrls: const [],
    likeCount: 93,
    commentCount: 28,
    likedBy: const [],
    createdAt: _now.subtract(const Duration(hours: 7)),
  ),
  CommunityPostEntity(
    id: 'mock_3',
    authorId: 'demo_user_3',
    authorName: 'Murat Demir',
    brand: 'BMW',
    title: 'iX3 için Türkiye\'deki en iyi CCS2 noktaları',
    content: 'BMW iX3 kullananlar için hazırladığım mini rehber: '
        '1) Trugo Otoyol durakları (150 kW, güvenilir) '
        '2) WAT İstanbul Anadolu noktaları (ortalama bekleme 15 dk) '
        '3) Eşarj AVM\'leri (yavaş ama AC Type 2 sorunsuz). '
        'İstanbul\'da günlük kullanımda asla menzil kaygısı yaşamıyorum.',
    photoUrls: const [],
    likeCount: 61,
    commentCount: 9,
    likedBy: const [],
    createdAt: _now.subtract(const Duration(hours: 14)),
  ),
  CommunityPostEntity(
    id: 'mock_4',
    authorId: 'demo_user_4',
    authorName: 'Zeynep Arslan',
    brand: 'Hyundai',
    title: 'IONIQ 6 kış menzili gerçekten bu kadar mı düşük?',
    content: 'İlk kışımı IONIQ 6 ile geçiriyorum. 0°C altında menzil '
        'yaklaşık %30 düşüyor, bu normal mi? Isıtmayı direksiyonla '
        'sınırlayıp koltuk ısıtmaya geçince fark azalıyor. '
        'Siz nasıl yönetiyorsunuz? Ön ısıtma uygulamayı kullanıyor musunuz?',
    photoUrls: const [],
    likeCount: 38,
    commentCount: 21,
    likedBy: const [],
    createdAt: _now.subtract(const Duration(days: 1)),
  ),
  CommunityPostEntity(
    id: 'mock_5',
    authorId: 'demo_user_5',
    authorName: 'Emre Çelik',
    brand: 'MG',
    title: 'MG4 ile 6 aylık izlenim — bütçe dostu EV',
    content: 'Türkiye\'de en uygun fiyatlı EV seçeneklerinden biri olan MG4\'ü '
        '6 aydır kullanıyorum. kWh başına maliyet hesapladığımda aylık '
        'yakıt tasarrufu ortalama 2.800₺. Serviste sorun yaşamadım, '
        'garanti kapsamı tatmin edici. Türkiye\'de şarj altyapısı '
        'beklenenden çok daha iyi — özellikle şehir içinde.',
    photoUrls: const [],
    likeCount: 74,
    commentCount: 16,
    likedBy: const [],
    createdAt: _now.subtract(const Duration(days: 2)),
  ),
  CommunityPostEntity(
    id: 'mock_6',
    authorId: 'demo_user_6',
    authorName: 'Fatma Öztürk',
    brand: 'Genel',
    title: 'Şarj etiketi: herkese uyan 5 kural',
    content:
        '1. Şarj tamamlanınca aracı hemen çek, sıra bekleyenler olabilir.\n'
        '2. Bağlantı kablosunu düzgün sar.\n'
        '3. Arızalı soket görürsen uygulamadan bildir.\n'
        '4. Beklerken müzik sesini kıs, diğer sürücüleri rahatsız etme.\n'
        '5. Acil olmadıkça DC hızlı şarjı %80\'de bırak, '
        'bataryana da iyilik yapmış olursun.',
    photoUrls: const [],
    likeCount: 112,
    commentCount: 34,
    likedBy: const [],
    createdAt: _now.subtract(const Duration(days: 3)),
  ),
];

final List<CommentEntity> _mockComments = [
  // mock_1 yorumları
  CommentEntity(
    id: 'mc_1',
    postId: 'mock_1',
    authorId: 'demo_user_2',
    authorName: 'Selin Kaya',
    content: 'Tebrikler! Ben de ilk uzun yolculuğumda aynı heyecanı yaşadım 🎉',
    createdAt: _now.subtract(const Duration(hours: 2)),
  ),
  CommentEntity(
    id: 'mc_2',
    postId: 'mock_1',
    authorId: 'demo_user_3',
    authorName: 'Murat Demir',
    content:
        'Hendek\'teki ZES genelde yoğun olur, sabah erken saatlerde boş bulunur.',
    createdAt: _now.subtract(const Duration(hours: 1, minutes: 30)),
  ),
  // mock_2 yorumları
  CommentEntity(
    id: 'mc_3',
    postId: 'mock_2',
    authorId: 'demo_user_4',
    authorName: 'Zeynep Arslan',
    content:
        '%80 şarj limiti konusunda kesinlikle katılıyorum, batarya sağlığı için kritik.',
    createdAt: _now.subtract(const Duration(hours: 6)),
  ),
  CommentEntity(
    id: 'mc_4',
    postId: 'mock_2',
    authorId: 'demo_user_5',
    authorName: 'Emre Çelik',
    content: 'SOH grafiği gerçekten çok işlevsel, her hafta kontrol ediyorum.',
    createdAt: _now.subtract(const Duration(hours: 5)),
  ),
  // mock_4 yorumları
  CommentEntity(
    id: 'mc_5',
    postId: 'mock_4',
    authorId: 'demo_user_1',
    authorName: 'Ahmet Yılmaz',
    content:
        'Kış menzil kaybı tüm EV\'lerde normal, %20-30 beklentisi içinde olunmalı.',
    createdAt: _now.subtract(const Duration(hours: 20)),
  ),
  CommentEntity(
    id: 'mc_6',
    postId: 'mock_4',
    authorId: 'demo_user_3',
    authorName: 'Murat Demir',
    content:
        'Ön ısıtma özelliği hayat kurtarıyor, şarjdeyken başlatmayı unutma!',
    createdAt: _now.subtract(const Duration(hours: 18)),
  ),
];
