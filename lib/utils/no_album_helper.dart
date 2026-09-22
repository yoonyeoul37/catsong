/// 앨범아트가 없을 때 대신 보여줄 기본 이미지 3장 중 하나를
/// key(곡 제목/경로 등)를 기준으로 항상 같은 것을 골라준다.
/// 같은 곡은 언제 봐도 같은 이미지, 다른 곡은 서로 다른 이미지가 섞여 나온다.
String noAlbumImagePath(String key) {
  const images = [
    'assets/no_album2.jpg',
    'assets/no_album3.jpg',
    'assets/no_album4.jpg',
  ];
  final index = key.hashCode.abs() % images.length;
  return images[index];
}