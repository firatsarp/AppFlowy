import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/mobile_select_option_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../grid/presentation/layout/sizes.dart';
import '../../cell_builder.dart';
import 'extension.dart';
import 'select_option_cell_bloc.dart';
import 'select_option_editor.dart';

class SelectOptionCellStyle extends GridCellStyle {
  String placeholder;
  EdgeInsets? cellPadding;

  SelectOptionCellStyle({
    required this.placeholder,
    this.cellPadding,
  });
}

class GridSingleSelectCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  late final SelectOptionCellStyle? cellStyle;

  GridSingleSelectCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as SelectOptionCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  GridCellState<GridSingleSelectCell> createState() => _SingleSelectCellState();
}

class _SingleSelectCellState extends GridCellState<GridSingleSelectCell> {
  late SelectOptionCellBloc _cellBloc;
  late final PopoverController _popover;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as SelectOptionCellController;
    _cellBloc = SelectOptionCellBloc(cellController: cellController)
      ..add(const SelectOptionCellEvent.initial());
    _popover = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        builder: (context, state) {
          return SelectOptionWrap(
            selectOptions: state.selectedOptions,
            cellStyle: widget.cellStyle,
            onCellEditing: (isFocus) =>
                widget.cellContainerNotifier.isFocus = isFocus,
            popoverController: _popover,
            cellControllerBuilder: widget.cellControllerBuilder,
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  void requestBeginFocus() => _popover.show();
}

//----------------------------------------------------------------
class GridMultiSelectCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  late final SelectOptionCellStyle? cellStyle;

  GridMultiSelectCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as SelectOptionCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  GridCellState<GridMultiSelectCell> createState() => _MultiSelectCellState();
}

class _MultiSelectCellState extends GridCellState<GridMultiSelectCell> {
  late SelectOptionCellBloc _cellBloc;
  late final PopoverController _popover;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as SelectOptionCellController;
    _cellBloc = SelectOptionCellBloc(cellController: cellController)
      ..add(const SelectOptionCellEvent.initial());
    _popover = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        builder: (context, state) {
          return SelectOptionWrap(
            selectOptions: state.selectedOptions,
            cellStyle: widget.cellStyle,
            onCellEditing: (isFocus) =>
                widget.cellContainerNotifier.isFocus = isFocus,
            popoverController: _popover,
            cellControllerBuilder: widget.cellControllerBuilder,
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  void requestBeginFocus() => _popover.show();
}

class SelectOptionWrap extends StatefulWidget {
  final List<SelectOptionPB> selectOptions;
  final SelectOptionCellStyle? cellStyle;
  final CellControllerBuilder cellControllerBuilder;
  final PopoverController popoverController;
  final void Function(bool) onCellEditing;

  const SelectOptionWrap({
    required this.selectOptions,
    required this.cellControllerBuilder,
    required this.onCellEditing,
    required this.popoverController,
    this.cellStyle,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SelectOptionWrapState();
}

class _SelectOptionWrapState extends State<SelectOptionWrap> {
  @override
  Widget build(BuildContext context) {
    final constraints = BoxConstraints.loose(
      Size(SelectOptionCellEditor.editorPanelWidth, 300),
    );
    final cellController =
        widget.cellControllerBuilder.build() as SelectOptionCellController;

    Widget child = Padding(
      padding: widget.cellStyle?.cellPadding ?? GridSize.cellContentInsets,
      child: _buildOptions(context),
    );

    if (PlatformExtension.isDesktopOrWeb) {
      child = AppFlowyPopover(
        controller: widget.popoverController,
        constraints: constraints,
        margin: EdgeInsets.zero,
        direction: PopoverDirection.bottomWithLeftAligned,
        popupBuilder: (BuildContext popoverContext) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCellEditing(true);
          });
          return SelectOptionCellEditor(
            cellController: cellController,
          );
        },
        onClose: () => widget.onCellEditing(false),
        child: child,
      );
    } else {
      child = FlowyButton(
        text: child,
        onTap: () {
          showMobileBottomSheet(
            context: context,
            padding: EdgeInsets.zero,
            builder: (context) {
              return MobileSelectOptionEditor(
                cellController: cellController,
              );
            },
          );
        },
      );
    }

    return child;
  }

  Widget _buildOptions(BuildContext context) {
    final Widget child;
    if (widget.selectOptions.isEmpty && widget.cellStyle != null) {
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: FlowyText.medium(
          widget.cellStyle!.placeholder,
          color: Theme.of(context).hintColor,
        ),
      );
    } else {
      final children = widget.selectOptions.map(
        (option) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SelectOptionTag.fromOption(
              context: context,
              option: option,
            ),
          );
        },
      ).toList();

      child = Wrap(
        runSpacing: 4,
        children: children,
      );
    }
    return Align(alignment: Alignment.centerLeft, child: child);
  }
}
