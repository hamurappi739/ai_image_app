enum AppSection {
  home,
  templatePhoto,
  photoshoots,
  customRequest,
  gallery,
  buy,
  profile,
  help,
}

extension AppSectionLabels on AppSection {
  String get drawerLabel => switch (this) {
        AppSection.home => 'Главная',
        AppSection.templatePhoto => 'Фото по шаблону',
        AppSection.photoshoots => 'Фотосессии',
        AppSection.customRequest => 'Свой запрос',
        AppSection.gallery => 'Готовые фото',
        AppSection.buy => 'Купить',
        AppSection.profile => 'Профиль',
        AppSection.help => 'Помощь',
      };

  String get screenTitle => switch (this) {
        AppSection.home => 'Главная',
        AppSection.templatePhoto => 'Фото по шаблону',
        AppSection.photoshoots => 'Фотосессии',
        AppSection.customRequest => 'Свой запрос',
        AppSection.gallery => 'Готовые фото',
        AppSection.buy => 'Купить',
        AppSection.profile => 'Профиль',
        AppSection.help => 'Помощь',
      };
}
