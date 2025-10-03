import 'package:flutter/material.dart';
import '../models/tracked_contact.dart';
import '../models/enums.dart';
import '../utils/priority_calculator.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'priority_indicator.dart';
import 'birthday_badge.dart';

/// Widget Card pour afficher un contact suivi
class ContactCard extends StatelessWidget {
  final TrackedContact contact;
  final VoidCallback? onTap;
  final VoidCallback? onCallTap;
  final VoidCallback? onSmsTap;
  final VoidCallback? onMarkContacted;

  const ContactCard({
    super.key,
    required this.contact,
    this.onTap,
    this.onCallTap,
    this.onSmsTap,
    this.onMarkContacted,
  });

  @override
  Widget build(BuildContext context) {
    final priority = calculatePriority(contact);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicateur de priorité
              PriorityIndicator(priority: priority, size: 16),
              const SizedBox(width: 12),

              // Informations du contact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et badge anniversaire
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact.contactName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        BirthdayBadge(birthday: contact.birthday),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Catégorie et fréquence
                    Text(
                      '${contact.category.displayName} • ${contact.frequency.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),

                    // Dernier contact
                    Text(
                      'Dernier contact: ${app_date_utils.getRelativeDateText(contact.lastContactDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Boutons d'action
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton Téléphone
                  IconButton(
                    icon: const Icon(Icons.phone, size: 20),
                    color: Colors.green,
                    onPressed: onCallTap,
                    tooltip: 'Appeler',
                  ),

                  // Bouton SMS
                  IconButton(
                    icon: const Icon(Icons.message, size: 20),
                    color: Colors.blue,
                    onPressed: onSmsTap,
                    tooltip: 'SMS',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
