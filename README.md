# GameCatalogModules

[![Module CI](https://github.com/muzafin/GameCatalogModules/actions/workflows/module-ci.yml/badge.svg)](https://github.com/muzafin/GameCatalogModules/actions/workflows/module-ci.yml)

Swift Package publik untuk aplikasi Game Catalog dengan product `GameCatalogDomain`, `GameCatalogData`, `Common`, `HomeFeature`, `DetailFeature`, `FavoriteFeature`, dan `AboutFeature`.

Platform minimum adalah iOS 15. Domain tests juga mendukung macOS 12 untuk eksekusi cepat di CI.

## Tests

```bash
swift test --package-path DomainTests --enable-code-coverage
```

Feature modules bergantung pada Domain dan Common. Data bergantung pada Domain untuk mengimplementasikan repository protocol. Domain tidak bergantung pada UIKit, Core Data, atau detail Data layer.
