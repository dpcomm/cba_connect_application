// 제네릭 Result 타입: 성공이면 Success, 실패면 Failure
sealed class Result<S, F> {
  const Result();
}

// 성공 결과를 담는 클래스
final class Success<S, F> extends Result<S, F> {
  final S value;
  const Success(this.value);
}

// 실패 결과를 담는 클래스
final class Failure<S, F> extends Result<S, F> {
  final F error;
  const Failure(this.error);
}
