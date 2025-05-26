import 'point_detail_state.dart';

abstract class PointDetailEvent {}

class FetchPointDetail extends PointDetailEvent {
  final String pointId;

  FetchPointDetail(this.pointId);
}

/// Событие переключения вкладки в детальной информации
class SwitchPointDetailTab extends PointDetailEvent {
  final PointDetailTab tab;

  SwitchPointDetailTab(this.tab);
}
