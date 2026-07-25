import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/models/guest_order.dart';
import 'package:konekto/theme/guest_app_theme.dart';

/// Enums não têm acesso a `BuildContext`, então o rótulo de status vem
/// daqui (único consumidor de `GuestOrderStatus`) em vez de um getter no
/// model. O rótulo muda conforme o tipo de pedido: item físico (Serviço de
/// Quarto) segue um fluxo de preparo/entrega, enquanto reserva agendada
/// (atividade, spa, mesa de restaurante) não "anda" fisicamente — só é
/// confirmada e depois concluída após o horário marcado.
String orderStatusLabel(AppLocalizations l10n, GuestOrderStatus status, bool isBooking) => switch (status) {
      GuestOrderStatus.pending => isBooking ? l10n.statusPendingBooking : l10n.statusPendingItem,
      GuestOrderStatus.inProgress => isBooking ? l10n.statusInProgressBooking : l10n.statusInProgressItem,
      GuestOrderStatus.completed => l10n.statusCompleted,
      GuestOrderStatus.cancelled => l10n.statusCancelled,
    };

/// Cartão de um pedido/reserva do hóspede — compartilhado entre
/// `MyOrdersPage` (todos os pedidos) e `BookingsPage`/Reservas (só os que
/// têm `scheduledFor`, via `GuestOrder.isBooking`).
class OrderCard extends StatelessWidget {
  final GuestOrder order;
  final GuestAppTheme theme;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const OrderCard({super.key, required this.order, required this.theme, required this.onEdit, required this.onCancel});

  String _formatScheduledFor(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$minute';
  }

  Color _statusColor(GuestAppTheme theme) => switch (order.status) {
        GuestOrderStatus.pending => theme.accent,
        GuestOrderStatus.inProgress => const Color(0xFF5B9BD5),
        GuestOrderStatus.completed => const Color(0xFF5CB85C),
        GuestOrderStatus.cancelled => theme.mutedColor,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(theme);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.itemName}${order.quantity > 1 ? ' ×${order.quantity}' : ''}',
                  style: theme.headline(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(theme.tokens.pillRadius)),
                child: Text(
                  orderStatusLabel(l10n, order.status, order.isBooking),
                  style: theme.body(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.price != null ? 'R\$ ${(order.price! * order.quantity).toStringAsFixed(2)}' : l10n.priceOnRequest,
            style: theme.body(fontSize: 13, fontWeight: FontWeight.w500, color: theme.mutedColor),
          ),
          if (order.scheduledFor != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 14, color: theme.accent),
                const SizedBox(width: 6),
                Text(
                  _formatScheduledFor(order.scheduledFor!),
                  style: theme.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.accent),
                ),
              ],
            ),
          ],
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.noteLabel(order.note!),
              style: theme.body(fontSize: 12.5, color: theme.mutedColor, fontStyle: FontStyle.italic),
            ),
          ],
          if (order.couponTitle != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 14, color: theme.accent),
                const SizedBox(width: 6),
                Text(
                  l10n.couponApplied(order.couponTitle!, order.discountAmount?.toStringAsFixed(2) ?? '0.00'),
                  style: theme.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.accent),
                ),
              ],
            ),
          ],
          if (order.isStaffRecorded) ...[
            const SizedBox(height: 6),
            Text(
              l10n.recordedByStaffTag,
              style: theme.body(fontSize: 11.5, color: theme.mutedColor, fontStyle: FontStyle.italic),
            ),
          ],
          if (order.isPartnerPaid) ...[
            const SizedBox(height: 6),
            Text(
              l10n.paidToPartnerTag(order.partnerName != null ? ' (${order.partnerName})' : ''),
              style: theme.body(fontSize: 11.5, color: theme.mutedColor, fontStyle: FontStyle.italic),
            ),
          ],
          if (order.status.isEditableByGuest) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 16, color: theme.accent),
                  label: Text(l10n.editAction, style: theme.body(fontSize: 12.5, color: theme.accent)),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: Icon(Icons.close, size: 16, color: Colors.red.shade400),
                  label: Text(l10n.cancelAction, style: theme.body(fontSize: 12.5, color: Colors.red.shade400)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
