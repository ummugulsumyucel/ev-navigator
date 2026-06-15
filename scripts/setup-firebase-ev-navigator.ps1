# ev-navigator-tr projesi farkli Google hesabindaysa once o hesapla giris yapin.
# Firebase Console: https://console.firebase.google.com/project/ev-navigator-tr

Write-Host "1/3 Mevcut Firebase oturumu kapatiliyor..." -ForegroundColor Yellow
firebase logout

Write-Host ""
Write-Host "2/3 ev-navigator-tr hesabinizla giris yapin (tarayici acilacak)..." -ForegroundColor Yellow
firebase login

Write-Host ""
Write-Host "3/3 FlutterFire yapilandiriliyor..." -ForegroundColor Yellow
$env:CI = "true"
dart pub global run flutterfire_cli:flutterfire configure `
  --project=ev-navigator-tr `
  --platforms=web,android `
  --yes

Write-Host ""
Write-Host "Tamamlandi. Uygulamayi yeniden baslatin: flutter run" -ForegroundColor Green
Write-Host "Authentication > Sign-in method > E-posta/Parola acik olmali:" -ForegroundColor Cyan
Write-Host "https://console.firebase.google.com/project/ev-navigator-tr/authentication/providers"
