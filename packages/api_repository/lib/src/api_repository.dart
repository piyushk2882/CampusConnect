/// {@template api_repository}
/// A fake api repository
/// {@endtemplate}
class ApiRepository {
  /// {@macro api_repository}
  const ApiRepository();

  List<String> fetchTodos() =>['Make Homework','GO to Gym','Buy Groceries'];
}
