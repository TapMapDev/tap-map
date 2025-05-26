abstract class PointDetailEvent {}

class FetchPointDetail extends PointDetailEvent {
  final String pointId;

  FetchPointDetail(this.pointId);
}
