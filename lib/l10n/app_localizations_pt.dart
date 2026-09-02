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
  String get goHome => 'Ir para o Início';

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
  String get signUpAppBarTitle => 'Cadastro';

  @override
  String get signUpBodyTitle => 'Criar Conta';

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
  String get confirmPasswordLabel => 'Confirmar Senha';

  @override
  String get confirmPasswordHint => 'Digite sua senha novamente';

  @override
  String get confirmPasswordRequired => 'Por favor, confirme sua senha';

  @override
  String get passwordMismatch => 'As senhas não coincidem';

  @override
  String get signUpButton => 'Cadastrar';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get signInLink => 'Entrar';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get userInformationTitle => 'Informações do Usuário';

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
  String get darkModeTitle => 'Modo Escuro';

  @override
  String get darkModeSubtitle => 'Alternar entre tema claro e escuro';

  @override
  String get logoutButton => 'Sair';

  @override
  String get searchGamesTitle => 'Buscar Jogos';

  @override
  String get searchGamesHint => 'Buscar jogos...';

  @override
  String get searchGamesTooltip => 'Buscar Jogos';

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
  String get screenshots => 'Capturas de Tela';

  @override
  String get videos => 'Vídeos';

  @override
  String get videoPlayerTitle => 'Vídeo';

  @override
  String get similarGames => 'Jogos Similares';

  @override
  String get whereToBuy => 'Onde Comprar';

  @override
  String get readMore => 'Ler Mais';

  @override
  String get readLess => 'Ler Menos';

  @override
  String get noVideosAvailable => 'Nenhum vídeo disponível';

  @override
  String get noScreenshotsAvailable => 'Nenhuma captura de tela disponível';

  @override
  String get errorLoadingData => 'Erro ao carregar dados';

  @override
  String get discoveryTrending => 'Em Alta';

  @override
  String get discoveryIndie => 'Indie';

  @override
  String get discoveryUpcoming => 'Em Breve';

  @override
  String get discoveryNewReleases => 'Novos Lançamentos';

  @override
  String get discoveryComingSoon => 'Chegando em Breve';

  @override
  String get recommendationsTitle => 'Recomendados para Você';

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
  String get libraryTitle => 'Minha Biblioteca';

  @override
  String get addGame => 'Adicionar Jogo';

  @override
  String get addFirstGame => 'Adicione Seu Primeiro Jogo';

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
  String get seeAll => 'Ver Todos';

  @override
  String get linkCopied => 'Link copiado!';

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
  String get mostAnticipated => 'Mais Aguardados';

  @override
  String get noUpcomingGames => 'Nenhum jogo futuro encontrado';

  @override
  String shareGameMessage(String gameName, String url) {
    return 'Confira $gameName no Picklog!\n$url';
  }

  @override
  String get removeFromLibrary => 'Remover da Biblioteca';

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
  String get libraryEntryUpdated =>
      'Entrada da biblioteca atualizada com sucesso.';

  @override
  String get gameAddedToLibrary => 'Jogo adicionado à biblioteca com sucesso.';

  @override
  String get editEntry => 'Editar Entrada';

  @override
  String get addToLibrary => 'Adicionar à Biblioteca';

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
  String get startDate => 'Data de Início';

  @override
  String get endDate => 'Data de Término';

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
}
