import 'package:bloc_test/bloc_test.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_bloc.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_event.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_state.dart';
import 'package:picklog/features/consent/bloc/consent_cubit.dart';
import 'package:picklog/features/consent/bloc/consent_state.dart';
import 'package:picklog/features/games/bloc/game_details_bloc.dart';
import 'package:picklog/features/games/bloc/game_details_event.dart';
import 'package:picklog/features/games/bloc/game_details_state.dart';
import 'package:picklog/features/games/bloc/game_search_bloc.dart';
import 'package:picklog/features/games/bloc/game_search_event.dart';
import 'package:picklog/features/games/bloc/game_search_state.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/settings/bloc/settings_bloc.dart';
import 'package:picklog/features/settings/bloc/settings_event.dart';
import 'package:picklog/features/settings/bloc/settings_state.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockLibraryBloc extends MockBloc<LibraryEvent, LibraryState>
    implements LibraryBloc {}

class MockConsentCubit extends MockCubit<ConsentState>
    implements ConsentCubit {}

class MockGameDetailsBloc extends MockBloc<GameDetailsEvent, GameDetailsState>
    implements GameDetailsBloc {}

class MockGameSearchBloc extends MockBloc<GameSearchEvent, GameSearchState>
    implements GameSearchBloc {}

class MockSignUpBloc extends MockBloc<SignUpEvent, SignUpState>
    implements SignUpBloc {}
