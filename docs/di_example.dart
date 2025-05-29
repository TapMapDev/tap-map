import 'package:flutter_bloc/flutter_bloc.dart';

/// Простой пример использования внедрения зависимостей через конструктор
/// без глобального сервис-локатора.
class ExampleRepository {
  const ExampleRepository();
  Future<void> fetch() async {/* ... */}
}

class ExampleCubit extends Cubit<int> {
  final ExampleRepository repository;
  ExampleCubit(this.repository) : super(0);
}

void setup() {
  final repo = ExampleRepository();
  final cubit = ExampleCubit(repo);
  // cubit можно передать через BlocProvider или использовать напрямую
}
