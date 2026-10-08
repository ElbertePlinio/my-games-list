// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Picklog';

  @override
  String get welcomeMessage => 'Bem Vindo ao Picklog';

  @override
  String get errorTitle => 'Erro';

  @override
  String get errorMessage => 'Ops! Algo deu errado.';

  @override
  String get offlineBannerMessage => 'Você está offline';

  @override
  String get loadingLabel => 'Carregando';

  @override
  String get goHome => 'Ir para o início';

  @override
  String get signInTitle => 'Entrar';

  @override
  String get signInSubtitle => 'Entre para continuar';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailHint => 'Digite seu e-mail';

  @override
  String get emailRequired => 'E-mail é obrigatório';

  @override
  String get emailInvalid => 'Digite um e-mail válido';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get passwordHint => 'Digite sua senha';

  @override
  String get passwordRequired => 'Senha é obrigatória';

  @override
  String get passwordMinLength => 'A senha deve ter pelo menos 6 caracteres';

  @override
  String get signInButton => 'Entrar';

  @override
  String get noAccount => 'Não tem uma conta?';

  @override
  String get signUpLink => 'Cadastre-se';

  @override
  String get signUpBodyTitle => 'Crie sua conta';

  @override
  String get signUpSubtitle => 'Cadastre-se para começar';

  @override
  String get usernameLabel => 'Nome de usuário';

  @override
  String get usernameHint => 'Escolha um nome de usuário';

  @override
  String get usernameRequired => 'Nome de usuário é obrigatório';

  @override
  String get usernameMinLength =>
      'Nome de usuário deve ter pelo menos 3 caracteres';

  @override
  String get usernameMaxLength =>
      'Nome de usuário deve ter no máximo 20 caracteres';

  @override
  String get passwordCreateHint => 'Crie uma senha';

  @override
  String get confirmPasswordLabel => 'Confirmar senha';

  @override
  String get confirmPasswordHint => 'Digite sua senha novamente';

  @override
  String get confirmPasswordRequired => 'Por favor, confirme sua senha';

  @override
  String get passwordMismatch => 'As senhas não coincidem';

  @override
  String get signUpButton => 'Criar conta';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get signInLink => 'Entrar';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get userInformationTitle => 'Conta';

  @override
  String nameFormat(String name) {
    return 'Nome: $name';
  }

  @override
  String emailFormat(String email) {
    return 'E-mail: $email';
  }

  @override
  String get unknown => 'Desconhecido';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get logoutButton => 'Sair';

  @override
  String get searchGamesTitle => 'Buscar';

  @override
  String get searchGamesHint => 'Buscar jogos...';

  @override
  String get searchGamesTooltip => 'Buscar jogos';

  @override
  String get searchGamesInitialMessage => 'Busque seus jogos favoritos';

  @override
  String searchGamesNoResults(String query) {
    return 'Nenhum resultado encontrado para \"$query\"';
  }

  @override
  String get searchGamesErrorMessage => 'Ocorreu um erro';

  @override
  String get searchGamesOffsetLimitReached =>
      'Limite máximo de resultados atingido. Por favor, refine sua busca.';

  @override
  String get searchGamesLoadMoreFailed => 'Falha ao carregar mais resultados';

  @override
  String get searchFiltersTitle => 'Filtros e ordenação';

  @override
  String get searchFiltersTooltip => 'Filtros e ordenação';

  @override
  String get searchFiltersApply => 'Ver resultados';

  @override
  String get searchFiltersClearAll => 'Limpar tudo';

  @override
  String get searchFiltersReset => 'Redefinir';

  @override
  String get searchFiltersLoadedScopeCaption =>
      'Os filtros se aplicam aos resultados carregados';

  @override
  String get searchSortLabel => 'Ordenar por';

  @override
  String get searchSortRelevance => 'Relevância';

  @override
  String get searchSortNameAsc => 'Nome (A–Z)';

  @override
  String get searchSortYearDesc => 'Mais recentes';

  @override
  String get searchSortYearAsc => 'Mais antigos';

  @override
  String get searchFilterGenresLabel => 'Gêneros';

  @override
  String get searchFilterPlatformsLabel => 'Plataformas';

  @override
  String get searchFilterYearLabel => 'Ano de lançamento';

  @override
  String get searchFilterNoFacets =>
      'Os filtros aparecem quando os resultados carregam.';

  @override
  String searchFilterChipYear(int year) {
    return 'Ano: $year';
  }

  @override
  String searchFilterChipSort(String sort) {
    return 'Ordenar: $sort';
  }

  @override
  String get searchNoResultsForFiltersTitle => 'Nenhum jogo com esses filtros';

  @override
  String get searchNoResultsForFiltersHint =>
      'Remova um filtro para ver mais jogos.';

  @override
  String get searchClearFilters => 'Limpar filtros';

  @override
  String get gameDetailsTitle => 'Detalhes do Jogo';

  @override
  String get developer => 'Desenvolvedor';

  @override
  String get rating => 'Avaliação';

  @override
  String get genres => 'Gêneros';

  @override
  String get platforms => 'Plataformas';

  @override
  String get storyline => 'Enredo';

  @override
  String get summary => 'Resumo';

  @override
  String get screenshots => 'Capturas de tela';

  @override
  String get videos => 'Vídeos';

  @override
  String get videoPlayerTitle => 'Vídeo';

  @override
  String get similarGames => 'Jogos similares';

  @override
  String get whereToBuy => 'Onde comprar';

  @override
  String get readMore => 'Ler mais';

  @override
  String get readLess => 'Ler menos';

  @override
  String get noVideosAvailable => 'Nenhum vídeo disponível';

  @override
  String get noScreenshotsAvailable => 'Nenhuma captura de tela disponível';

  @override
  String get errorLoadingData => 'Erro ao carregar dados';

  @override
  String get discoveryTrending => 'Em alta';

  @override
  String get discoveryIndie => 'Indie';

  @override
  String get discoveryUpcoming => 'Em breve';

  @override
  String get discoveryNewReleases => 'Novos lançamentos';

  @override
  String get discoveryComingSoon => 'Chegando em breve';

  @override
  String get recommendationsTitle => 'Recomendados para você';

  @override
  String get signInWithGoogle => 'Continuar com Google';

  @override
  String get orContinueWith => 'ou continuar com';

  @override
  String get signInWithEmail => 'Entrar com e-mail';

  @override
  String get recommended => 'Recomendado';

  @override
  String get browseTitle => 'Explorar';

  @override
  String get browseGenresError =>
      'Não foi possível carregar os gêneros. Tente novamente.';

  @override
  String get browseGenresEmpty => 'Nenhum gênero disponível no momento.';

  @override
  String get browseGenreGamesError =>
      'Não foi possível carregar os jogos deste gênero. Tente novamente.';

  @override
  String get browseGenreEmpty => 'Nenhum jogo encontrado neste gênero ainda.';

  @override
  String get browseRetry => 'Tentar novamente';

  @override
  String get browseGenresSection => 'Gêneros';

  @override
  String get offlineTitle => 'Você está offline';

  @override
  String get offlineErrorMessage => 'Verifique sua conexão e tente novamente.';

  @override
  String gameCoverLabel(String name) {
    return 'Capa de $name';
  }

  @override
  String get clearSearch => 'Limpar busca';

  @override
  String get clearDate => 'Limpar data';

  @override
  String screenshotLabel(String name) {
    return 'Captura de tela de $name';
  }

  @override
  String get favorited => 'Favoritado';

  @override
  String libraryEntryLabel(String name, String status) {
    return '$name, $status';
  }

  @override
  String libraryEntryScoreLabel(int score) {
    return 'nota $score';
  }

  @override
  String genreCardLabel(String name) {
    return 'Gênero $name';
  }

  @override
  String get navHome => 'Início';

  @override
  String get navBrowse => 'Explorar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navProfile => 'Perfil';

  @override
  String get libraryTitle => 'Biblioteca';

  @override
  String get addGame => 'Adicionar jogo';

  @override
  String get addFirstGame => 'Adicione seu primeiro jogo';

  @override
  String get failedToLoadLibrary => 'Falha ao carregar a biblioteca';

  @override
  String favoritesWithCount(int count) {
    return 'Favoritos ($count)';
  }

  @override
  String get emptyFavorites =>
      'Nenhum jogo favorito ainda.\nToque no ícone de coração para adicionar favoritos!';

  @override
  String get emptyStatusGames =>
      'Nenhum jogo com este status ainda.\nAdicione jogos com este status para vê-los aqui.';

  @override
  String get emptyLibrary =>
      'Sua biblioteca está vazia.\nComece a adicionar jogos para acompanhar sua coleção!';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get noUserInfo => 'Nenhuma informação de usuário disponível';

  @override
  String get switchToList => 'Mudar para lista';

  @override
  String get switchToGrid => 'Mudar para grade';

  @override
  String get failedToLoadGames => 'Falha ao carregar os jogos';

  @override
  String get reachedEnd => 'Você chegou ao fim';

  @override
  String get somethingWentWrong => 'Algo deu errado';

  @override
  String get noGamesFound => 'Nenhum jogo encontrado';

  @override
  String get noGamesInCategory => 'Ainda não há jogos nesta categoria.';

  @override
  String get seeAll => 'Ver tudo';

  @override
  String get linkCopied => 'Link copiado';

  @override
  String get addToFavorites => 'Adicionar aos favoritos';

  @override
  String get removeFromFavorites => 'Remover dos favoritos';

  @override
  String get share => 'Compartilhar';

  @override
  String get addToLibraryShort => 'Adicionar';

  @override
  String get links => 'Links';

  @override
  String get statusPlanned => 'Planejado';

  @override
  String get statusPlaying => 'Jogando';

  @override
  String get statusFinished => 'Finalizado';

  @override
  String get statusDropped => 'Abandonado';

  @override
  String get statusOnHold => 'Pausado';

  @override
  String get mostAnticipated => 'Mais aguardados';

  @override
  String get noUpcomingGames => 'Nenhum jogo futuro encontrado';

  @override
  String shareGameMessage(String gameName, String url) {
    return 'Confira $gameName no Picklog!\n$url';
  }

  @override
  String get removeFromLibrary => 'Remover da biblioteca';

  @override
  String removeFromLibraryConfirm(String gameName) {
    return 'Tem certeza de que deseja remover \"$gameName\" da sua biblioteca?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Remover';

  @override
  String get save => 'Salvar';

  @override
  String get libraryEntryUpdated => 'Registro atualizado';

  @override
  String get editEntry => 'Editar registro';

  @override
  String get addToLibrary => 'Adicionar à biblioteca';

  @override
  String get statusLabel => 'Status';

  @override
  String get platformLabel => 'Plataforma';

  @override
  String get selectPlatformHint => 'Selecione a plataforma (opcional)';

  @override
  String get noneOption => 'Nenhum';

  @override
  String get score => 'Nota';

  @override
  String get favorite => 'Favorito';

  @override
  String get playtime => 'Tempo de Jogo';

  @override
  String get hours => 'Horas';

  @override
  String get minutes => 'Minutos';

  @override
  String get dates => 'Datas';

  @override
  String get startDate => 'Data de início';

  @override
  String get endDate => 'Data de término';

  @override
  String get difficulty => 'Dificuldade';

  @override
  String get difficultyHint => 'ex.: Normal, Difícil, Pesadelo';

  @override
  String get notes => 'Notas';

  @override
  String get notesHint => 'Adicione suas notas...';

  @override
  String get notSet => 'Não definido';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get onboardingTrackTitle => 'Acompanhe cada jogo que você joga';

  @override
  String get onboardingTrackSubtitle =>
      'Monte sua biblioteca pessoal e mantenha sua coleção organizada por status.';

  @override
  String get onboardingDiscoverTitle => 'Descubra o que jogar a seguir';

  @override
  String get onboardingDiscoverSubtitle =>
      'Explore títulos em alta, joias escondidas e próximos lançamentos feitos para você.';

  @override
  String get onboardingShareTitle => 'Deixe do seu jeito';

  @override
  String get onboardingShareSubtitle =>
      'Marque favoritos, avalie seus jogos e continue de onde parou.';

  @override
  String get onboardingSkip => 'Pular';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingGetStarted => 'Começar';

  @override
  String get searchGamesInitialTitle => 'Encontre seu próximo favorito';

  @override
  String get searchGamesInitialHint =>
      'Busque pelo título para adicionar jogos à sua biblioteca.';

  @override
  String get searchGamesNoResultsTitle => 'Nenhuma correspondência ainda';

  @override
  String get emptyLibraryTitle => 'Sua biblioteca está vazia';

  @override
  String get emptyLibraryHint =>
      'Comece a adicionar jogos para acompanhar sua coleção e nunca perder o progresso.';

  @override
  String get privacyDataTitle => 'Privacidade e dados';

  @override
  String get exportDataTitle => 'Exportar meus dados';

  @override
  String get exportDataSubtitle =>
      'Baixe uma cópia dos dados da sua conta em formato JSON.';

  @override
  String get exportDataSuccess => 'A exportação dos seus dados está pronta.';

  @override
  String get exportDataError =>
      'Não foi possível exportar seus dados. Tente novamente.';

  @override
  String get deleteAccountTitle => 'Excluir minha conta';

  @override
  String get deleteAccountSubtitle =>
      'Exclua permanentemente sua conta e todos os seus dados.';

  @override
  String get deleteAccountDialogTitle => 'Excluir conta?';

  @override
  String get deleteAccountDialogBody =>
      'Isto exclui permanentemente sua conta e todos os seus dados. Esta ação não pode ser desfeita.';

  @override
  String deleteAccountConfirmLabel(String word) {
    return 'Digite $word para confirmar';
  }

  @override
  String get deleteAccountConfirmWord => 'EXCLUIR';

  @override
  String get deleteAccountConfirmButton => 'Excluir conta';

  @override
  String get deleteAccountError =>
      'Não foi possível excluir sua conta. Tente novamente.';

  @override
  String get consentBannerTitle => 'Suas escolhas de privacidade';

  @override
  String get consentBannerBody =>
      'Escolha quais dados você permite. Você pode alterar isso quando quiser em Configurações.';

  @override
  String get consentAcceptAll => 'Aceitar tudo';

  @override
  String get consentRejectAll => 'Recusar tudo';

  @override
  String get consentCustomize => 'Personalizar';

  @override
  String get consentCustomizeTitle => 'Escolha o que você permite';

  @override
  String get consentSave => 'Salvar';

  @override
  String get consentAnalyticsTitle => 'Análise de uso';

  @override
  String get consentAnalyticsSubtitle =>
      'Dados de uso anônimos para ajudar a melhorar o app.';

  @override
  String get consentCrashTitle => 'Relatórios de falhas';

  @override
  String get consentCrashSubtitle =>
      'Enviar relatórios de falhas e erros para ajudar a corrigir problemas.';

  @override
  String get consentPushTitle => 'Notificações push';

  @override
  String get consentPushSubtitle =>
      'Receba notificações sobre seus jogos e atualizações.';

  @override
  String get privacyPolicyTitle => 'Política de Privacidade';

  @override
  String get termsTitle => 'Termos de Uso';

  @override
  String get legalTitle => 'Jurídico';

  @override
  String get legalDraftBanner =>
      'RASCUNHO — texto provisório. Substitua pelo texto jurídico final antes do lançamento.';

  @override
  String get legalLoadError =>
      'Não foi possível carregar este documento. Tente novamente mais tarde.';

  @override
  String get signUpAcceptPrefix => 'Eu aceito a ';

  @override
  String get signUpAcceptPrivacyLink => 'Política de Privacidade';

  @override
  String get signUpAcceptConjunction => ' e os ';

  @override
  String get signUpAcceptTermsLink => 'Termos de Uso';

  @override
  String get signUpAcceptRequired =>
      'Aceite a Política de Privacidade e os Termos para continuar.';

  @override
  String get signInLegalNotice =>
      'Ao continuar, você aceita nossa Política de Privacidade e os Termos de Uso.';

  @override
  String get errorNetwork =>
      'Não foi possível conectar ao Picklog. Verifique sua conexão.';

  @override
  String get errorNotFound => 'Não encontramos isso.';

  @override
  String get errorUnauthorized => 'Sua sessão terminou. Entre novamente.';

  @override
  String get errorServer =>
      'O servidor teve um problema. Tente de novo em instantes.';

  @override
  String get errorUnknown => 'Algo deu errado. Tente de novo.';

  @override
  String get splashTagline => 'Sua biblioteca de jogos, registrada';

  @override
  String get onboardingTrackEyebrow => '01 · Registre';

  @override
  String get onboardingDiscoverEyebrow => '02 · Descubra';

  @override
  String get onboardingShareEyebrow => '03 · Do seu jeito';

  @override
  String pageIndicatorLabel(int current, int total) {
    return 'Página $current de $total';
  }

  @override
  String get signInEyebrow => 'Picklog · Entrar';

  @override
  String get signInHeadline => 'Bem-vindo de volta';

  @override
  String get signUpEyebrow => 'Picklog · Criar conta';

  @override
  String gameWithScoreLabel(String name, int score) {
    return '$name, nota $score';
  }

  @override
  String get recommendationsSubtitle =>
      'Escolhidos pelos gêneros que você joga';

  @override
  String get collectionsSectionTitle => 'Coleções';

  @override
  String get featuredEyebrow => 'Destaque';

  @override
  String get featuredError => 'Não foi possível carregar os destaques.';

  @override
  String countdownDaysHoursMinutes(int days, int hours, int minutes) {
    return '${days}d ${hours}h ${minutes}min';
  }

  @override
  String countdownHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String countdownMinutes(int minutes) {
    return '${minutes}min';
  }

  @override
  String get countdownReleased => 'Já disponível';

  @override
  String anticipatedHypes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hypes',
      one: '1 hype',
    );
    return '$_temp0';
  }

  @override
  String get playtimeNone => 'Sem tempo de jogo';

  @override
  String playtimeMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String playtimeHoursShort(String hours) {
    return '$hours h';
  }

  @override
  String get homeEyebrow => 'Picklog · Início';

  @override
  String homeGreetingNight(String name) {
    return 'Boa madrugada, $name';
  }

  @override
  String homeGreetingMorning(String name) {
    return 'Bom dia, $name';
  }

  @override
  String homeGreetingAfternoon(String name) {
    return 'Boa tarde, $name';
  }

  @override
  String homeGreetingEvening(String name) {
    return 'Boa noite, $name';
  }

  @override
  String get homeGreetingAnonymous => 'Que bom te ver';

  @override
  String get homeSubtitle => 'O que você vai jogar agora?';

  @override
  String get libraryEyebrow => 'Picklog · Biblioteca';

  @override
  String libraryGameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos',
      one: '1 jogo',
      zero: 'Nenhum jogo ainda',
    );
    return '$_temp0';
  }

  @override
  String get libraryFavoriteFailed =>
      'Não foi possível atualizar o favorito. Tente de novo.';

  @override
  String get libraryDeleteFailed =>
      'Não foi possível remover o jogo. Ele voltou para sua biblioteca.';

  @override
  String get libraryRefreshFailed =>
      'Não foi possível atualizar sua biblioteca.';

  @override
  String get librarySaveFailed => 'Não foi possível salvar. Tente de novo.';

  @override
  String lightboxPosition(int current, int total) {
    return '$current / $total';
  }

  @override
  String get lightboxClose => 'Fechar';

  @override
  String get lightboxPrevious => 'Captura anterior';

  @override
  String get lightboxNext => 'Próxima captura';

  @override
  String get inYourLibrary => 'Na sua biblioteca';

  @override
  String get yourScore => 'Sua nota';

  @override
  String get igdbScore => 'Nota de críticos e jogadores';

  @override
  String get releaseDate => 'Lançamento';

  @override
  String get detailsAbout => 'Sobre';

  @override
  String get searchLoadMoreFailed =>
      'Não foi possível carregar mais resultados.';

  @override
  String get browseEyebrow => 'Picklog · Explorar';

  @override
  String get libraryDetailsSection => 'Mais detalhes';

  @override
  String get libraryDetailsHint => 'Tempo de jogo, datas, dificuldade e notas';

  @override
  String get scoreNotSet => 'Sem nota';

  @override
  String get themeTitle => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get settingsEyebrow => 'Picklog · Configurações';

  @override
  String get profileEyebrow => 'Picklog · Perfil';

  @override
  String get routeNotFoundMessage =>
      'Esta página não existe ou mudou de lugar.';

  @override
  String get librarySortUpdated => 'Atualizados recentemente';

  @override
  String get librarySortAdded => 'Adicionados recentemente';

  @override
  String get librarySortName => 'Nome (A-Z)';

  @override
  String get librarySortScore => 'Sua nota';

  @override
  String get librarySortPlaytime => 'Mais jogados';

  @override
  String get librarySortRelease => 'Data de lançamento';

  @override
  String get librarySortRating => 'Nota da comunidade';

  @override
  String get collectionErrorDuplicateName =>
      'Você já tem uma coleção com esse nome.';

  @override
  String get collectionErrorLimit =>
      'Você pode ter até 50 coleções. Exclua uma para criar outra.';

  @override
  String get collectionErrorEntriesLimit =>
      'Esta coleção está cheia (500 jogos).';

  @override
  String get collectionErrorNameInvalid => 'Use de 1 a 60 caracteres no nome.';

  @override
  String get collectionErrorDescriptionTooLong =>
      'A descrição pode ter até 280 caracteres.';

  @override
  String get collectionErrorNotFound => 'Esta coleção não existe mais.';

  @override
  String recommendationReasonSimilar(String name) {
    return 'Porque você curtiu $name';
  }

  @override
  String get recommendationReasonSimilarGeneric =>
      'Parecido com jogos que você curte';

  @override
  String recommendationReasonGenre(String genre) {
    return 'Mais $genre';
  }

  @override
  String get recommendationReasonGenreGeneric =>
      'Combina com seus gêneros favoritos';

  @override
  String get recommendationReasonPopular => 'Em alta agora';

  @override
  String get exploreSortPopular => 'Populares';

  @override
  String get exploreSortRating => 'Mais bem avaliados';

  @override
  String get exploreSortNewest => 'Mais novos';

  @override
  String get exploreSortOldest => 'Mais antigos';

  @override
  String get exploreSortName => 'A-Z';

  @override
  String get filterOptionsFailed => 'Não foi possível carregar as opções.';

  @override
  String get filterReleaseYears => 'Anos de lançamento';

  @override
  String filterYearRangeValue(int from, int to) {
    return '$from-$to';
  }

  @override
  String get filterMinRating => 'Nota mínima';

  @override
  String get filterAnyRating => 'Qualquer';

  @override
  String filterRatingValue(int rating) {
    return 'Nota $rating+';
  }

  @override
  String get filterGenreFallback => 'Gênero';

  @override
  String get filterPlatformFallback => 'Plataforma';

  @override
  String filterRemoveChip(String label) {
    return 'Remover $label';
  }

  @override
  String get exploreTitle => 'Explorar';

  @override
  String get searchExploreCatalog => 'Explorar o catálogo';

  @override
  String get searchSortLoadedScopeCaption =>
      'A ordenação reorganiza os resultados já carregados.';

  @override
  String get exploreFiltersButton => 'Filtros';

  @override
  String get exploreFiltersTitle => 'Filtros';

  @override
  String get exploreEmptyTitle => 'Nenhum jogo encontrado';

  @override
  String get exploreEmptyHint =>
      'Tente menos filtros ou um intervalo de anos maior.';

  @override
  String exploreResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos exibidos',
      one: '1 jogo exibido',
    );
    return '$_temp0';
  }

  @override
  String get exploreEndOfResults => 'Você chegou ao fim.';

  @override
  String get undo => 'Desfazer';

  @override
  String libraryChangeStatusTitle(String name) {
    return 'Mudar o status de $name';
  }

  @override
  String get collectionEditTitle => 'Editar coleção';

  @override
  String get collectionNewTitle => 'Nova coleção';

  @override
  String get collectionNameLabel => 'Nome';

  @override
  String get collectionDescriptionLabel => 'Descrição (opcional)';

  @override
  String get collectionCreateAction => 'Criar';

  @override
  String get collectionDeleteTitle => 'Excluir coleção?';

  @override
  String collectionDeleteConfirm(String name) {
    return '\"$name\" será excluída. Os jogos continuam na sua biblioteca.';
  }

  @override
  String get collectionDeleteAction => 'Excluir';

  @override
  String get collectionPickerTitle => 'Adicionar às coleções';

  @override
  String get collectionPickerEmpty =>
      'Nenhuma coleção ainda. Crie uma para agrupar jogos do seu jeito.';

  @override
  String collectionGameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos',
      one: '1 jogo',
      zero: 'Nenhum jogo',
    );
    return '$_temp0';
  }

  @override
  String get collectionsEmptyTitle => 'Nenhuma coleção ainda';

  @override
  String get collectionsEmptyHint =>
      'Agrupe jogos em listas como Cooperativo no sofá ou Jogos de conforto.';

  @override
  String get collectionDeleted => 'Coleção excluída';

  @override
  String collectionCardLabel(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos',
      one: '1 jogo',
    );
    return '$name, $_temp0';
  }

  @override
  String get collectionActions => 'Ações da coleção';

  @override
  String get statsTotal => 'Total';

  @override
  String get statsHours => 'Horas';

  @override
  String libraryStatsSemantics(
    int total,
    int playing,
    int finished,
    String hours,
  ) {
    return '$total jogos, $playing jogando, $finished finalizados, $hours horas';
  }

  @override
  String get libraryFiltersTitle => 'Filtrar biblioteca';

  @override
  String get libraryFavoritesFilter => 'Favoritos';

  @override
  String get libraryFilterMinScore => 'Nota mínima';

  @override
  String get libraryFilterCollection => 'Coleção';

  @override
  String libraryScoreChip(int score) {
    return 'Nota $score+';
  }

  @override
  String libraryUnfavorited(String name) {
    return '$name saiu dos favoritos';
  }

  @override
  String libraryFavorited(String name) {
    return '$name entrou nos favoritos';
  }

  @override
  String libraryStatusChanged(String name, String status) {
    return '$name agora está como $status';
  }

  @override
  String get libraryEntryActions => 'Mais ações';

  @override
  String get libraryChangeStatus => 'Mudar status';

  @override
  String get rouletteTitle => 'Escolha por mim';

  @override
  String get librarySegmentGames => 'Jogos';

  @override
  String get librarySegmentCollections => 'Coleções';

  @override
  String get librarySearchHint => 'Buscar títulos';

  @override
  String get librarySortTooltip => 'Ordenar';

  @override
  String get libraryViewList => 'Ver em lista';

  @override
  String get libraryViewGrid => 'Ver em grade';

  @override
  String libraryMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
      zero: 'Nenhum resultado',
    );
    return '$_temp0';
  }

  @override
  String get libraryNoMatchesTitle => 'Nenhum jogo encontrado';

  @override
  String get libraryNoMatchesHint => 'Tente outra busca ou limpe os filtros.';

  @override
  String get rouletteEyebrow => 'Roleta do backlog';

  @override
  String rouletteCandidates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos no sorteio',
      one: '1 jogo no sorteio',
      zero: 'Nenhum jogo para sortear',
    );
    return '$_temp0';
  }

  @override
  String get rouletteAnyPlatform => 'Qualquer plataforma';

  @override
  String get rouletteAnyLength => 'Qualquer tempo jogado';

  @override
  String rouletteMaxHours(int hours) {
    return 'Até $hours h jogadas';
  }

  @override
  String get rouletteNoMatch =>
      'Nenhum jogo do backlog combina com esses filtros.';

  @override
  String get rouletteHint =>
      'Gire para o Picklog escolher seu próximo jogo do backlog.';

  @override
  String get rouletteStartPlaying => 'Começar a jogar';

  @override
  String get rouletteSpinAgain => 'Girar de novo';

  @override
  String get rouletteSpin => 'Girar';

  @override
  String rouletteStarted(String name) {
    return 'Divirta-se com $name!';
  }

  @override
  String get rouletteEmptyTitle => 'Seu backlog está vazio';

  @override
  String get rouletteEmptyHint =>
      'Adicione jogos como Planejado ou Pausado e o Picklog escolhe um para você.';

  @override
  String get collectionEyebrow => 'Coleção';

  @override
  String get collectionEmptyTitle => 'Nenhum jogo aqui ainda';

  @override
  String get collectionEmptyHint =>
      'Adicione jogos pela ficha do jogo ou pelo menu da biblioteca.';

  @override
  String collectionEntryRemoved(String name) {
    return '$name saiu da coleção';
  }

  @override
  String get collectionRemoveEntry => 'Remover da coleção';

  @override
  String get profileTopGenres => 'Gêneros favoritos';

  @override
  String get profileTopPlatforms => 'Plataformas favoritas';

  @override
  String get profileStatsFailed =>
      'Não foi possível carregar suas estatísticas.';

  @override
  String get profileSettingsHint => 'Conta, tema, privacidade e idioma';

  @override
  String get profileMemberLine => 'Membro do Picklog';

  @override
  String profileMemberLineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Membro do Picklog · $count jogos registrados',
      one: 'Membro do Picklog · 1 jogo registrado',
      zero: 'Membro do Picklog · Nenhum jogo registrado',
    );
    return '$_temp0';
  }

  @override
  String get profileStatGames => 'Jogos';

  @override
  String get profileStatAverage => 'Nota média';

  @override
  String get profileStatBacklog => 'Backlog';

  @override
  String get profileStatusDistribution => 'Por status';

  @override
  String profileYearInReviewLabel(int year) {
    return 'Abrir sua retrospectiva de $year';
  }

  @override
  String get yearInReviewEyebrow => 'Retrospectiva';

  @override
  String get profileYearInReviewHint => 'Seu ano nos games, card a card.';

  @override
  String get profileAchievements => 'Conquistas';

  @override
  String profileAchievementsValue(int unlocked, int total) {
    return '$unlocked de $total desbloqueadas';
  }

  @override
  String profileBacklogValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos no backlog',
      one: '1 jogo no backlog',
      zero: 'Backlog vazio',
    );
    return '$_temp0';
  }

  @override
  String get profileFavorites => 'Favoritos';

  @override
  String get profileFavoritesEmpty =>
      'Toque no coração de um jogo para vê-lo aqui.';

  @override
  String yearShareText(int year) {
    return 'Meu $year nos games no Picklog';
  }

  @override
  String get yearShareFailed => 'Não foi possível compartilhar a imagem.';

  @override
  String yearInReviewTitle(int year) {
    return 'Retrospectiva $year';
  }

  @override
  String get yearPickerTooltip => 'Escolher ano';

  @override
  String get yearShareTooltip => 'Compartilhar';

  @override
  String get yearIntroTitle => 'Seu ano nos games';

  @override
  String get yearIntroEmpty =>
      'Nada registrado neste ano ainda. Adicione jogos para montar sua história.';

  @override
  String get yearIntroHint => 'Veja o que você adicionou, terminou e amou.';

  @override
  String get yearGamesAdded => 'Jogos adicionados';

  @override
  String get yearGamesFinished => 'Jogos finalizados';

  @override
  String get yearHoursPlayed => 'Horas jogadas';

  @override
  String get yearByMonth => 'Mês a mês';

  @override
  String yearByMonthSemantics(int added, int finished) {
    return 'Gráfico por mês: $added adicionados e $finished finalizados no total';
  }

  @override
  String get yearLegendAdded => 'Adicionados';

  @override
  String get yearLegendFinished => 'Finalizados';

  @override
  String get yearTopRated => 'Mais bem avaliados';

  @override
  String get yearTopGenres => 'Gêneros favoritos';

  @override
  String yearGenreChip(String name, int count) {
    return '$name · $count';
  }

  @override
  String get yearFirstFinished => 'Primeiro jogo finalizado';

  @override
  String get yearShareEyebrow => 'Compartilhe seu ano';

  @override
  String get yearShareAction => 'Compartilhar imagem';

  @override
  String get yearShareAdded => 'Adicionados';

  @override
  String get yearShareFinished => 'Finalizados';

  @override
  String get yearShareHours => 'Horas';

  @override
  String yearShareTopRated(String name) {
    return 'Mais bem avaliado: $name';
  }

  @override
  String yearShareTopGenre(String genre) {
    return 'Gênero favorito: $genre';
  }

  @override
  String get browseExploreTitle => 'Explore o catálogo';

  @override
  String get browseExploreHint => 'Filtre por gênero, plataforma, ano e nota.';

  @override
  String get aiEyebrowPlayNext => 'IA · Jogar a seguir';

  @override
  String get aiEyebrowDiscover => 'IA · Descobrir';

  @override
  String get aiPlayNextTitle => 'Jogar a seguir';

  @override
  String get aiPlayNextHeadline => 'O que eu jogo hoje à noite?';

  @override
  String get aiPlayNextSubtitle =>
      'Conte seu humor e seu tempo. O Picklog escolhe do seu backlog.';

  @override
  String get aiMoodLabel => 'Humor';

  @override
  String get aiMoodChill => 'Tranquilo';

  @override
  String get aiMoodIntense => 'Intenso';

  @override
  String get aiMoodStory => 'História';

  @override
  String get aiMoodSocial => 'Social';

  @override
  String get aiMoodQuick => 'Rápido';

  @override
  String get aiMoodChallenge => 'Desafio';

  @override
  String get aiTimeLabel => 'Tempo disponível';

  @override
  String aiDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String aiDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String aiDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get aiDurationFourPlus => '4 h+';

  @override
  String get aiPlatformLabel => 'Plataforma';

  @override
  String get aiPlatformAny => 'Qualquer plataforma';

  @override
  String get aiNoteLabel => 'Algo mais? (opcional)';

  @override
  String get aiNoteHint => 'Por exemplo: algo que eu possa pausar sempre';

  @override
  String get aiGenerateButton => 'Sugerir jogos';

  @override
  String get aiRegenerateButton => 'Gerar de novo';

  @override
  String aiRemainingToday(int remaining, int limit) {
    return '$remaining de $limit restantes hoje';
  }

  @override
  String aiRemainingTodayShort(int remaining) {
    return '$remaining restantes hoje';
  }

  @override
  String get aiLoadingPlayNext1 => 'Lendo seu backlog';

  @override
  String get aiLoadingPlayNext2 => 'Pesando seu humor e seu tempo';

  @override
  String get aiLoadingPlayNext3 => 'Comparando gêneros e notas';

  @override
  String get aiLoadingPlayNext4 => 'Escolhendo as melhores opções';

  @override
  String get aiLoadingDiscover1 => 'Lendo seu gosto';

  @override
  String get aiLoadingDiscover2 => 'Procurando jogos novos';

  @override
  String get aiLoadingDiscover3 => 'Conferindo o catálogo';

  @override
  String get aiResultsTitle => 'Suas escolhas';

  @override
  String get aiTopPick => 'Melhor escolha';

  @override
  String aiSessionLength(String duration) {
    return 'Cerca de $duration por sessão';
  }

  @override
  String get aiStartPlaying => 'Começar a jogar';

  @override
  String get aiNowPlaying => 'Jogando agora';

  @override
  String get aiOpenGame => 'Abrir';

  @override
  String get aiStartPlayingError =>
      'Não foi possível atualizar este jogo. Tente de novo.';

  @override
  String get aiEmptyBacklogTitle => 'Seu backlog está vazio';

  @override
  String get aiEmptyBacklogMessage =>
      'O Jogar a seguir escolhe entre jogos planejados, em andamento ou em pausa. Adicione alguns primeiro.';

  @override
  String get aiGoExplore => 'Explorar jogos';

  @override
  String get aiGoSearch => 'Buscar jogos';

  @override
  String get aiErrorUnavailable =>
      'As sugestões com IA não estão disponíveis agora.';

  @override
  String get aiErrorConsentRequired =>
      'Ative as sugestões com IA para usar este recurso.';

  @override
  String get aiErrorQuotaExceeded =>
      'Você usou todas as sugestões com IA de hoje. Volte amanhã.';

  @override
  String get aiErrorUpstream =>
      'O serviço de IA não respondeu. Tente de novo em instantes.';

  @override
  String get aiUnavailableTitle => 'Sugestões com IA desligadas';

  @override
  String get aiQuotaTitle => 'Limite diário atingido';

  @override
  String get aiConsentNeededTitle => 'As sugestões com IA precisam do seu OK';

  @override
  String get aiConsentNeededMessage =>
      'O Picklog só envia dados ao serviço de IA depois que você concordar.';

  @override
  String get aiReviewConsent => 'Revisar e ativar';

  @override
  String get aiConsentTitle => 'Ativar sugestões com IA?';

  @override
  String get aiConsentBody =>
      'Para criar sugestões, o Picklog envia à OpenAI os nomes, status, notas, gêneros e tempo de jogo dos jogos da sua biblioteca, além do texto que você digitar.';

  @override
  String get aiConsentNever => 'O Picklog nunca envia seu email nem seu nome.';

  @override
  String get aiConsentRevoke =>
      'Você pode desligar isso a qualquer momento nas Configurações.';

  @override
  String get aiConsentAccept => 'Ativar';

  @override
  String get aiConsentDecline => 'Agora não';

  @override
  String get aiConsentSaveError =>
      'Não foi possível salvar sua escolha. Tente de novo.';

  @override
  String get aiSettingsTitle => 'Sugestões com IA';

  @override
  String get aiSettingsSwitch => 'Permitir sugestões com IA';

  @override
  String get aiSettingsSwitchOn =>
      'O Picklog pode enviar dados de jogos da sua biblioteca à OpenAI.';

  @override
  String get aiSettingsSwitchOff => 'Nada é enviado à OpenAI.';

  @override
  String aiSettingsUsage(int used, int limit) {
    return '$used de $limit usadas hoje';
  }

  @override
  String get aiSettingsUnavailable =>
      'As sugestões com IA não estão disponíveis neste servidor.';

  @override
  String get aiSettingsLoadError =>
      'Não foi possível carregar suas configurações de IA.';

  @override
  String get aiHomeCardSubtitle =>
      'Receba escolhas do seu backlog para seu humor e seu tempo.';

  @override
  String get aiHomeCardAction => 'Escolha por mim';

  @override
  String get aiDiscoverTitle => 'Descobrir com IA';

  @override
  String get aiHomeDiscoverSubtitle =>
      'Descreva o que você quer e encontre jogos novos.';

  @override
  String get aiDiscoverSubtitle =>
      'Descreva o que você quer jogar. O Picklog sugere jogos que você ainda não tem.';

  @override
  String get aiDiscoverPromptLabel => 'Do que você está com vontade?';

  @override
  String get aiDiscoverPromptHint =>
      'Por exemplo: um jogo relaxante de fazenda';

  @override
  String get aiDiscoverSubmit => 'Encontrar jogos';

  @override
  String get aiDiscoverSuggestion1 =>
      'Jogos aconchegantes para o fim de semana';

  @override
  String get aiDiscoverSuggestion2 => 'Como Hades, mas mais calmo';

  @override
  String get aiDiscoverSuggestion3 => 'Jogos de história com menos de 10 horas';

  @override
  String get aiDiscoverSuggestionsLabel => 'Experimente';

  @override
  String get aiDiscoverEmptyTitle => 'Nenhum jogo novo encontrado';

  @override
  String get aiDiscoverEmptyMessage => 'Tente outro pedido.';

  @override
  String aiRatingLabel(int score) {
    return 'Nota $score';
  }

  @override
  String get accountsTitle => 'Contas conectadas';

  @override
  String get accountsEyebrow => 'Picklog · Contas';

  @override
  String get accountsIntro =>
      'Conecte perfis públicos de jogos para trazer conquistas e tempo de jogo. O Picklog usa só identificadores públicos e nunca pede suas senhas.';

  @override
  String get accountsSettingsSubtitle =>
      'Steam, Xbox, RetroAchievements, PlayStation';

  @override
  String get accountsUnavailable => 'Indisponível';

  @override
  String get accountsUnavailableMessage =>
      'Este serviço ainda não está configurado.';

  @override
  String get accountsExperimental => 'Experimental';

  @override
  String get accountsNotLinked => 'Não conectada';

  @override
  String get accountsLink => 'Conectar';

  @override
  String accountsLinkTitle(String provider) {
    return 'Conectar $provider';
  }

  @override
  String get accountsSteamFieldLabel => 'URL ou ID do perfil Steam';

  @override
  String get accountsSteamHelp =>
      'Cole o link do seu perfil, o nome da sua URL personalizada ou o seu SteamID de 17 dígitos.';

  @override
  String get accountsSteamPublicNote =>
      'Os detalhes de jogos precisam ser públicos. Na Steam, abra seu perfil, escolha Editar perfil, depois Configurações de privacidade, e defina Detalhes dos jogos como Público.';

  @override
  String get accountsXboxFieldLabel => 'Gamertag da Xbox';

  @override
  String get accountsXboxHelp =>
      'Sua gamertag como aparece no seu perfil Xbox.';

  @override
  String get accountsRaFieldLabel => 'Usuário do RetroAchievements';

  @override
  String get accountsRaHelp => 'Seu nome de usuário em retroachievements.org.';

  @override
  String get accountsPsnFieldLabel => 'ID online da PSN';

  @override
  String get accountsPsnHelp =>
      'Seu ID online. Sua lista de troféus precisa estar visível para qualquer pessoa.';

  @override
  String get accountsPsnExperimentalNote =>
      'O suporte ao PlayStation é experimental. Ele lê só listas públicas de troféus.';

  @override
  String get accountsLinkSubmit => 'Conectar conta';

  @override
  String accountsLinkedMessage(String provider) {
    return '$provider conectada. Toque em Sincronizar agora para importar seus dados.';
  }

  @override
  String accountsLastSynced(String time) {
    return 'Última sincronização: $time';
  }

  @override
  String get accountsNeverSynced => 'Ainda não sincronizada';

  @override
  String get accountsSyncing => 'Sincronizando';

  @override
  String get accountsSyncOk => 'Atualizada';

  @override
  String get accountsSyncError => 'A última sincronização falhou';

  @override
  String get accountsSyncNow => 'Sincronizar agora';

  @override
  String get accountsImportToggle =>
      'Também importar jogos para minha biblioteca';

  @override
  String get accountsImportHelp =>
      'Adiciona jogos que você tem ou jogou e que ainda não estão na sua biblioteca.';

  @override
  String accountsSyncStarted(String provider) {
    return 'Sincronizando $provider. Isso pode levar alguns minutos.';
  }

  @override
  String accountsSyncFinished(String provider) {
    return 'Sincronização de $provider concluída';
  }

  @override
  String get accountsUnlink => 'Desconectar';

  @override
  String accountsUnlinkTitle(String provider) {
    return 'Desconectar $provider?';
  }

  @override
  String get accountsUnlinkMessage =>
      'O Picklog apaga as conquistas e o progresso importados desta conta. Os jogos que já estão na sua biblioteca continuam.';

  @override
  String accountsUnlinkedMessage(String provider) {
    return '$provider desconectada';
  }

  @override
  String get accountsErrorNotFound =>
      'Não encontramos essa conta. Confira o que você digitou e tente de novo.';

  @override
  String get accountsErrorPrivate =>
      'Este perfil é privado. Deixe os detalhes de jogos públicos e tente de novo.';

  @override
  String get accountsErrorSyncTooSoon =>
      'Esta conta foi sincronizada há pouco. Tente de novo em alguns minutos.';

  @override
  String get accountsErrorUnavailable =>
      'Este serviço não está disponível agora.';

  @override
  String get accountsErrorInvalid => 'Digite um identificador válido.';

  @override
  String get accountsErrorUpstream =>
      'O serviço não respondeu. Tente de novo mais tarde.';

  @override
  String get accountsErrorGameNotFound =>
      'Não encontramos conquistas para este jogo.';

  @override
  String get timeJustNow => 'agora mesmo';

  @override
  String timeMinutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String get achievementsTitle => 'Conquistas';

  @override
  String get achievementsEyebrow => 'Picklog · Conquistas';

  @override
  String get achievementsCompletion => 'Conclusão geral';

  @override
  String achievementsUnlockedOf(int unlocked, int total) {
    return '$unlocked de $total desbloqueadas';
  }

  @override
  String achievementsGamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos',
      one: '1 jogo',
    );
    return '$_temp0';
  }

  @override
  String get achievementsRecentTitle => 'Desbloqueadas recentemente';

  @override
  String get achievementsGamesTitle => 'Jogos';

  @override
  String get achievementsFilterAll => 'Todos';

  @override
  String get achievementsEmptyTitle => 'Nenhuma conquista ainda';

  @override
  String get achievementsEmptyMessage =>
      'Conecte Steam, Xbox, RetroAchievements ou PlayStation para ver suas conquistas aqui.';

  @override
  String get achievementsConnectAction => 'Conectar uma conta';

  @override
  String achievementsRarity(String percent) {
    return '$percent% dos jogadores';
  }

  @override
  String get achievementsRare => 'Rara';

  @override
  String achievementsUnlockedOn(String date) {
    return 'Desbloqueada em $date';
  }

  @override
  String get achievementsLocked => 'Bloqueada';

  @override
  String achievementsLastPlayed(String date) {
    return 'Jogado em $date';
  }

  @override
  String get achievementsGameEmpty =>
      'Este jogo não tem conquistas para mostrar.';

  @override
  String get aiDiscoverHeadline => 'Encontre seu próximo jogo favorito';
}
