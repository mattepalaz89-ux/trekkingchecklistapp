// Copyright (c) 2026 Matteo Palazzi. All rights reserved.
// Application: Trekking Checklist
// Package ID: com.matteopalazzi.trekkingchecklist

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  await NotificationService.instance.init();
  runApp(const TrekkingChecklistApp());
}

// ============================================================================
// 1. SERVIZIO NOTIFICHE NATIVE ANDROID (Conforme Google Play - No Exact Alarm)
// ============================================================================
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> requestPermissionIfNeeded() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  Future<void> syncBackpackReminder(
    BackpackModel bp,
    String title,
    String bodyIntro,
    String Function(BackpackItem) getItemName,
  ) async {
    await cancelReminder(bp.notifId);
    if (bp.reminderIso == null) return;

    final scheduledLocal = DateTime.tryParse(bp.reminderIso!);
    if (scheduledLocal == null || !scheduledLocal.isAfter(DateTime.now())) {
      return;
    }

    final pendingReminderItems = bp.items
        .where((i) => !i.excluded && i.reminder && !i.done)
        .map((i) => '• ${getItemName(i)}')
        .toList();

    if (pendingReminderItems.isEmpty) return;

    final hasPerm = await requestPermissionIfNeeded();
    if (!hasPerm) return;

    final fullBody = '$bodyIntro\n${pendingReminderItems.join('\n')}';
    final utcInstant = tz.TZDateTime.from(scheduledLocal.toUtc(), tz.UTC);

    final androidDetails = AndroidNotificationDetails(
      'trek_reminders_channel',
      'Promemoria Partenza',
      channelDescription: 'Avvisi per gli oggetti da inserire nello zaino prima della partenza',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(fullBody, contentTitle: title),
    );

    await _plugin.zonedSchedule(
      bp.notifId,
      title,
      fullBody,
      utcInstant,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(int notifId) async {
    await _plugin.cancel(notifId);
  }
}

// ============================================================================
// 2. PALETTE COLORI E TEMA GRAFICO
// ============================================================================
class AppColors {
  static const Color bgStone = Color(0xFFF4F5F0);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color forestDark = Color(0xFF1A3326);
  static const Color forestPrimary = Color(0xFF274C3A);
  static const Color forestLight = Color(0xFFE7EFEA);
  static const Color terracotta = Color(0xFFC25B3E);
  static const Color terracottaLight = Color(0xFFFBEFEA);
  static const Color textMain = Color(0xFF1D231F);
  static const Color textMuted = Color(0xFF647067);
  static const Color borderSoft = Color(0xFFDFE5DF);
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color danger = Color(0xFFD32F2F);
}

// ============================================================================
// 3. DIZIONARIO MULTILINGUA (IT, EN, FR, ES)
// ============================================================================
const Map<String, Map<String, String>> kUiStrings = {
  'it': {
    'homeTitle': 'Prepara lo zaino. Parti sereno.',
    'homeSub': 'La tua checklist su misura per escursioni, trekking e cammini.',
    'btnNewBp': 'Crea un nuovo zaino',
    'savedBpTitle': 'I tuoi zaini in archivio',
    'statusLabel': 'Stato zaino',
    'btnResetChecks': 'Azzera spunte',
    'btnEditParams': 'Modifica parametri',
    'inlineReadyTxt': 'Zaino completo al 100%!',
    'inlineReadyBtn': 'Riepilogo',
    'noReminderSet': 'Nessuna sveglia impostata',
    'itemsToRemember': 'oggetti da ricordare. Imposta ora!',
    'alarmLabel': 'Sveglia',
    'btnSetAlarm': 'Imposta',
    'btnEditAlarm': 'Modifica',
    'excludedLabel': 'Oggetti non portati',
    'btnAddCustom': 'Oggetto',
    'btnContinueLater': 'Finisci più tardi',
    'successTitle': 'Zaino Pronto!',
    'successSub': 'Hai preparato tutto l\'equipaggiamento necessario. Sei pronto a partire in totale sicurezza.',
    'statReady': 'Pronti',
    'statExcluded': 'Esclusi',
    'statRem': 'Promemoria',
    'btnShareFriends': 'Condividi lista con amici',
    'btnBackBp': 'Rivedi o modifica zaino',
    'btnBackHome': 'Torna alla Home',
    'modalRemTitle': 'Promemoria Partenza',
    'modalRemSub': 'Scegli data e ora per ricevere un unico avviso sul telefono con gli oggetti segnati con 🔔.',
    'btnPickDateTime': 'Scegli data e ora',
    'btnSaveRem': 'Salva Promemoria',
    'btnClearRem': 'Disattiva Sveglia',
    'btnClose': 'Chiudi',
    'btnCancel': 'Annulla',
    'btnSave': 'Salva',
    'btnConfirm': 'Conferma',
    'modalParamsTitle': 'Modifica Parametri',
    'modalParamsSub': 'Cambia una o più risposte: la lista si aggiornerà senza perdere le spunte già inserite.',
    'btnApplyParams': 'Applica modifiche',
    'guideTitle': 'Come funziona l\'app',
    'btnGotIt': 'Ho capito',
    'discTitle': 'Avvertenza di sicurezza',
    'discText': 'Trekking Checklist è uno strumento di promemoria. I suggerimenti generati non sostituiscono la preparazione tecnica, il giudizio personale o i bollettini meteo. L\'utente è responsabile della propria attrezzatura e sicurezza.',
    'stepOf': 'Passo {cur} di {tot}',
    'completedCount': 'completati',
    'inReminderTag': 'Nel promemoria',
    'restoreBtn': 'Ripristina',
    'emptyCategory': 'Nessun oggetto in questa categoria.',
    'defaultBpName': 'Escursione',
    'promptRename': 'Nuovo nome per questo zaino:',
    'promptCustom': 'Aggiungi oggetto in',
    'confirmDeleteTitle': 'Elimina zaino',
    'confirmDelete': 'Vuoi eliminare definitivamente questo zaino dall\'archivio?',
    'confirmReset': 'Vuoi azzerare tutte le spunte di questo zaino per riutilizzarlo?',
    'toastRenamed': 'Zaino rinominato!',
    'toastReset': 'Spunte azzerate! Zaino pronto per essere riutilizzato.',
    'toastUpdatedParams': 'Parametri aggiornati ({diff})! Spunte mantenute.',
    'toastExcluded': 'spostato tra gli oggetti non portati',
    'toastRestored': 'ripristinato nello zaino',
    'toastAddedRem': 'aggiunto alla sveglia',
    'toastRemovedRem': 'rimosso dalla sveglia',
    'toastAlarmSaved': 'Sveglia di partenza programmata!',
    'toastAlarmCleared': 'Sveglia disattivata',
    'toastSavedLater': 'Zaino salvato! Puoi completarlo quando vuoi.',
    'notifBodyIntro': 'Ricordati di mettere nello zaino prima di uscire:',
    'g1Title': 'Spunta gli oggetti',
    'g1Desc': 'Tocca la casella man mano che inserisci ogni attrezzatura nello zaino.',
    'g2Title': 'Campanella e Sveglia Unica',
    'g2Desc': 'Tocca 🔔 sugli oggetti dell\'ultimo minuto e imposta data e ora nel banner in alto.',
    'g3Title': 'Escludi ciò che non porti',
    'g3Desc': 'Tocca ✕ per scartare un oggetto consigliato: finirà in fondo e potrai ripristinarlo quando vuoi.',
    'g4Title': 'Archivio e Riuso',
    'g4Desc': 'Tutti gli zaini restano salvati in Home. Puoi riaprirli, rinominarli (✏️), azzerare le spunte (🔄) o cambiare meteo (⚙️).',
  },
  'en': {
    'homeTitle': 'Pack smart. Hike with confidence.',
    'homeSub': 'Your custom packing list for day hikes, treks, and long trails.',
    'btnNewBp': 'Create new backpack',
    'savedBpTitle': 'Your saved backpacks',
    'statusLabel': 'Packing progress',
    'btnResetChecks': 'Reset checks',
    'btnEditParams': 'Edit parameters',
    'inlineReadyTxt': 'Backpack 100% ready!',
    'inlineReadyBtn': 'Summary',
    'noReminderSet': 'No departure alarm set',
    'itemsToRemember': 'items to remember. Set time!',
    'alarmLabel': 'Alarm',
    'btnSetAlarm': 'Set alarm',
    'btnEditAlarm': 'Edit',
    'excludedLabel': 'Items left behind',
    'btnAddCustom': 'Add item',
    'btnContinueLater': 'Finish later',
    'successTitle': 'Backpack Ready!',
    'successSub': 'All essential gear is packed. You are ready to hit the trail safely.',
    'statReady': 'Packed',
    'statExcluded': 'Excluded',
    'statRem': 'Reminders',
    'btnShareFriends': 'Share list with friends',
    'btnBackBp': 'Review or edit backpack',
    'btnBackHome': 'Back to Home',
    'modalRemTitle': 'Departure Reminder',
    'modalRemSub': 'Pick date and time to get a single notification for all items marked with 🔔.',
    'btnPickDateTime': 'Pick date & time',
    'btnSaveRem': 'Save Reminder',
    'btnClearRem': 'Turn Off Alarm',
    'btnClose': 'Close',
    'btnCancel': 'Cancel',
    'btnSave': 'Save',
    'btnConfirm': 'Confirm',
    'modalParamsTitle': 'Edit Parameters',
    'modalParamsSub': 'Change one or more answers: your list will update while keeping existing checkmarks.',
    'btnApplyParams': 'Apply changes',
    'guideTitle': 'Quick Usage Guide',
    'btnGotIt': 'Got it',
    'discTitle': 'Safety Warning',
    'discText': 'Trekking Checklist is a reminder tool. Suggestions do not replace technical preparation, personal judgment or weather reports. You are responsible for your own gear and safety.',
    'stepOf': 'Step {cur} of {tot}',
    'completedCount': 'packed',
    'inReminderTag': 'In reminder',
    'restoreBtn': 'Restore',
    'emptyCategory': 'No items in this category.',
    'defaultBpName': 'Hike',
    'promptRename': 'Enter a new name for this backpack:',
    'promptCustom': 'Add custom item to',
    'confirmDeleteTitle': 'Delete backpack',
    'confirmDelete': 'Delete this backpack from your archive?',
    'confirmReset': 'Uncheck all items to reuse this backpack?',
    'toastRenamed': 'Backpack renamed!',
    'toastReset': 'Checks reset! Ready to pack again.',
    'toastUpdatedParams': 'Parameters updated ({diff})! Checks kept.',
    'toastExcluded': 'moved to excluded items',
    'toastRestored': 'restored to list',
    'toastAddedRem': 'added to reminder',
    'toastRemovedRem': 'removed from reminder',
    'toastAlarmSaved': 'Departure reminder scheduled!',
    'toastAlarmCleared': 'Reminder turned off',
    'toastSavedLater': 'Backpack saved! You can continue packing anytime.',
    'notifBodyIntro': 'Don\'t forget to pack before leaving:',
    'g1Title': 'Check off your gear',
    'g1Desc': 'Tap the checkbox as you pack each item into your backpack.',
    'g2Title': 'Bell & Single Alarm',
    'g2Desc': 'Tap 🔔 on last-minute items (water, food, powerbank) and set one date & time in the top banner.',
    'g3Title': 'Exclude unneeded items',
    'g3Desc': 'Tap ✕ to skip a recommended item. It moves to the bottom drawer where you can restore it anytime.',
    'g4Title': 'Archive & Reuse',
    'g4Desc': 'Backpacks are auto-saved. Reopen them anytime to rename (✏️), reset checks (🔄), or change trip settings (⚙️).',
  },
  'fr': {
    'homeTitle': 'Préparez votre sac. Partez l\'esprit léger.',
    'homeSub': 'Votre liste sur mesure pour randonnées, treks et grands chemins.',
    'btnNewBp': 'Créer un nouveau sac',
    'savedBpTitle': 'Vos sacs enregistrés',
    'statusLabel': 'État du sac',
    'btnResetChecks': 'Réinitialiser',
    'btnEditParams': 'Modifier critères',
    'inlineReadyTxt': 'Sac prêt à 100% !',
    'inlineReadyBtn': 'Résumé',
    'noReminderSet': 'Aucun rappel configuré',
    'itemsToRemember': 'objets à rappeler. Régler l\'heure !',
    'alarmLabel': 'Rappel',
    'btnSetAlarm': 'Régler',
    'btnEditAlarm': 'Modifier',
    'excludedLabel': 'Objets non emportés',
    'btnAddCustom': 'Ajouter',
    'btnContinueLater': 'Terminer plus tard',
    'successTitle': 'Sac Prêt !',
    'successSub': 'Tout l\'équipement essentiel est prêt. Bonne randonnée en toute sécurité !',
    'statReady': 'Prêts',
    'statExcluded': 'Exclus',
    'statRem': 'Rappels',
    'btnShareFriends': 'Partager avec des amis',
    'btnBackBp': 'Revoir ou modifier le sac',
    'btnBackHome': 'Retour à l\'accueil',
    'modalRemTitle': 'Rappel de Départ',
    'modalRemSub': 'Choisissez la date et l\'heure pour recevoir une alerte unique pour les objets 🔔.',
    'btnPickDateTime': 'Choisir date et heure',
    'btnSaveRem': 'Enregistrer le rappel',
    'btnClearRem': 'Désactiver l\'alarme',
    'btnClose': 'Fermer',
    'btnCancel': 'Annuler',
    'btnSave': 'Sauvegarder',
    'btnConfirm': 'Confirmer',
    'modalParamsTitle': 'Modifier les Critères',
    'modalParamsSub': 'Modifiez une ou plusieurs réponses : la liste sera mise à jour en gardant vos coches.',
    'btnApplyParams': 'Appliquer',
    'guideTitle': 'Guide d\'utilisation',
    'btnGotIt': 'J\'ai compris',
    'discTitle': 'Avertissement de sécurité',
    'discText': 'Trekking Checklist est un outil de rappel. Il ne remplace pas la préparation technique, le jugement personnel ou la météo. Vous êtes responsable de votre matériel et de votre sécurité.',
    'stepOf': 'Étape {cur} sur {tot}',
    'completedCount': 'prêts',
    'inReminderTag': 'Dans le rappel',
    'restoreBtn': 'Restaurer',
    'emptyCategory': 'Aucun objet dans cette catégorie.',
    'defaultBpName': 'Randonnée',
    'promptRename': 'Nouveau nom pour ce sac à dos :',
    'promptCustom': 'Ajouter un objet dans',
    'confirmDeleteTitle': 'Supprimer le sac',
    'confirmDelete': 'Supprimer définitivement ce sac de l\'archive ?',
    'confirmReset': 'Décocher tous les objets pour réutiliser ce sac ?',
    'toastRenamed': 'Sac renommé !',
    'toastReset': 'Cases décochées ! Prêt à être réutilisé.',
    'toastUpdatedParams': 'Critères mis à jour ({diff}) ! Coches conservées.',
    'toastExcluded': 'déplacé dans les objets ignorés',
    'toastRestored': 'restauré dans la liste',
    'toastAddedRem': 'ajouté au rappel',
    'toastRemovedRem': 'retiré du rappel',
    'toastAlarmSaved': 'Rappel de départ programmé !',
    'toastAlarmCleared': 'Rappel désactivé',
    'toastSavedLater': 'Sac enregistré ! Vous pourrez continuer plus tard.',
    'notifBodyIntro': 'N\'oubliez pas de mettre dans votre sac avant de partir :',
    'g1Title': 'Cochez votre matériel',
    'g1Desc': 'Touchez la case au fur et à mesure que vous mettez chaque objet dans le sac.',
    'g2Title': 'Cloche et Rappel Unique',
    'g2Desc': 'Touchez 🔔 sur les objets de dernière minute et réglez une seule alarme en haut.',
    'g3Title': 'Exclure un objet',
    'g3Desc': 'Touchez ✕ pour ignorer un objet : il sera rangé en bas où vous pourrez le restaurer.',
    'g4Title': 'Archive & Édition',
    'g4Desc': 'Vos sacs sont sauvegardés. Rouvrez-les pour les renommer (✏️), tout décocher (🔄) ou modifier la météo (⚙️).',
  },
  'es': {
    'homeTitle': 'Prepara tu mochila. Sal sin preocupaciones.',
    'homeSub': 'Tu lista a medida para excursiones, trekkings y grandes rutas.',
    'btnNewBp': 'Crear nueva mochila',
    'savedBpTitle': 'Tus mochilas guardadas',
    'statusLabel': 'Estado de la mochila',
    'btnResetChecks': 'Reiniciar marcas',
    'btnEditParams': 'Editar parámetros',
    'inlineReadyTxt': '¡Mochila lista al 100%!',
    'inlineReadyBtn': 'Resumen',
    'noReminderSet': 'Sin alarma configurada',
    'itemsToRemember': 'objetos por recordar. ¡Pon la hora!',
    'alarmLabel': 'Alarma',
    'btnSetAlarm': 'Configurar',
    'btnEditAlarm': 'Editar',
    'excludedLabel': 'Objetos descartados',
    'btnAddCustom': 'Añadir',
    'btnContinueLater': 'Terminar más tarde',
    'successTitle': '¡Mochila Lista!',
    'successSub': 'Todo el equipo esencial está preparado. ¡Buen camino con total seguridad!',
    'statReady': 'Listos',
    'statExcluded': 'Descartados',
    'statRem': 'Recordatorios',
    'btnShareFriends': 'Compartir lista con amigos',
    'btnBackBp': 'Revisar o editar mochila',
    'btnBackHome': 'Volver al inicio',
    'modalRemTitle': 'Recordatorio de Salida',
    'modalRemSub': 'Elige fecha y hora para recibir un único aviso con los objetos marcados con 🔔.',
    'btnPickDateTime': 'Elegir fecha y hora',
    'btnSaveRem': 'Guardar Recordatorio',
    'btnClearRem': 'Desactivar Alarma',
    'btnClose': 'Cerrar',
    'btnCancel': 'Cancelar',
    'btnSave': 'Guardar',
    'btnConfirm': 'Confirmar',
    'modalParamsTitle': 'Editar Parámetros',
    'modalParamsSub': 'Cambia una o más respuestas: la lista se actualizará conservando tus marcas.',
    'btnApplyParams': 'Aplicar cambios',
    'guideTitle': 'Guía rápida de uso',
    'btnGotIt': 'Entendido',
    'discTitle': 'Advertencia de seguridad',
    'discText': 'Trekking Checklist es una herramienta de recordatorio. No reemplaza la preparación técnica, el juicio personal o la meteorología. Eres responsable de tu propio equipo y seguridad.',
    'stepOf': 'Paso {cur} de {tot}',
    'completedCount': 'listos',
    'inReminderTag': 'En recordatorio',
    'restoreBtn': 'Restaurar',
    'emptyCategory': 'Ningún objeto en esta categoría.',
    'defaultBpName': 'Ruta',
    'promptRename': 'Nuevo nombre para esta mochila:',
    'promptCustom': 'Añadir objeto en',
    'confirmDeleteTitle': 'Eliminar mochila',
    'confirmDelete': '¿Eliminar esta mochila del archivo?',
    'confirmReset': '¿Desmarcar todos los objetos para reutilizar esta mochila?',
    'toastRenamed': '¡Mochila renombrada!',
    'toastReset': '¡Marcas reiniciadas! Lista para reutilizar.',
    'toastUpdatedParams': '¡Parámetros actualizados ({diff})!',
    'toastExcluded': 'movido a descartados',
    'toastRestored': 'restaurado a la lista',
    'toastAddedRem': 'añadido al recordatorio',
    'toastRemovedRem': 'quitado del recordatorio',
    'toastAlarmSaved': '¡Alarma de salida programada!',
    'toastAlarmCleared': 'Alarma desactivada',
    'toastSavedLater': '¡Mochila guardada! Puedes continuar cuando quieras.',
    'notifBodyIntro': 'Recuerda meter en la mochila antes de salir:',
    'g1Title': 'Marca tu equipo',
    'g1Desc': 'Toca la casilla a medida que guardas cada objeto en tu mochila.',
    'g2Title': 'Campana y Alarma Única',
    'g2Desc': 'Toca 🔔 en los objetos de última hora y programa una sola fecha y hora arriba.',
    'g3Title': 'Descarta lo que no lleves',
    'g3Desc': 'Toca ✕ para excluir un objeto recomendado. Pasará al final donde podrás restaurarlo.',
    'g4Title': 'Archivo y Reuso',
    'g4Desc': 'Tus mochilas se guardan solas. Ábrelas para renombrarlas (✏️), reiniciar marcas (🔄) o cambiar el clima (⚙️).',
  },
};

// ============================================================================
// 4. CATEGORIE, DOMANDE E DATABASE UFFICIALE v3 (81 OGGETTI)
// ============================================================================
class CategoryDef {
  final String id;
  final Map<String, String> names;
  const CategoryDef(this.id, this.names);
}

const List<CategoryDef> kCategories = [
  CategoryDef('CAT-1', {'it': 'Abbigliamento', 'en': 'Clothing', 'fr': 'Vêtements', 'es': 'Ropa y Calzado'}),
  CategoryDef('CAT-2', {'it': 'Accessori', 'en': 'Accessories', 'fr': 'Accessoires', 'es': 'Accesorios'}),
  CategoryDef('CAT-3', {'it': 'Attrezzatura Tecnica', 'en': 'Technical Gear', 'fr': 'Matériel Technique', 'es': 'Equipo Técnico'}),
  CategoryDef('CAT-4', {'it': 'Cibo e Idratazione', 'en': 'Food & Hydration', 'fr': 'Nourriture et Hydratation', 'es': 'Comida e Hidratación'}),
  CategoryDef('CAT-5', {'it': 'Igiene e Pernottamento', 'en': 'Hygiene & Sleeping', 'fr': 'Hygiène et Couchage', 'es': 'Higiene y Pernocta'}),
  CategoryDef('CAT-6', {'it': 'Sicurezza e Orientamento', 'en': 'Safety & Navigation', 'fr': 'Sécurité et Orientation', 'es': 'Seguridad y Orientación'}),
];

class QuestionOption {
  final String val;
  final String icon;
  final Map<String, String> title;
  final Map<String, String> sub;
  const QuestionOption({required this.val, required this.icon, required this.title, required this.sub});
}

class QuestionDef {
  final String id;
  final Map<String, String> title;
  final Map<String, String> desc;
  final List<QuestionOption> options;
  const QuestionDef({required this.id, required this.title, required this.desc, required this.options});
}

const List<QuestionDef> kQuestions = [
  QuestionDef(
    id: 'durata',
    title: {'it': 'Quanto durerà l\'uscita?', 'en': 'How long is your trip?', 'fr': 'Quelle est la durée de la sortie ?', 'es': '¿Cuánto durará la salida?'},
    desc: {'it': 'Seleziona la durata complessiva del percorso.', 'en': 'Select the total duration of your route.', 'fr': 'Sélectionnez la durée totale de votre itinéraire.', 'es': 'Selecciona la duración total del recorrido.'},
    options: [
      QuestionOption(
        val: 'giornata', icon: '☀️',
        title: {'it': 'Escursione in giornata (0 notti)', 'en': 'Day hike (0 nights)', 'fr': 'Randonnée à la journée (0 nuit)', 'es': 'Excursión de un día (0 noches)'},
        sub: {'it': 'Rientro previsto entro sera', 'en': 'Return expected by evening', 'fr': 'Retour prévu avant le soir', 'es': 'Regreso previsto antes de la noche'},
      ),
      QuestionOption(
        val: 'weekend', icon: '🏕️',
        title: {'it': 'Weekend (1-2 notti)', 'en': 'Weekend (1-2 nights)', 'fr': 'Week-end (1-2 nuits)', 'es': 'Fin de semana (1-2 noches)'},
        sub: {'it': 'Uscita breve con pernottamento fuori', 'en': 'Short trip with overnight stay', 'fr': 'Court séjour avec nuitée', 'es': 'Salida corta con pernocta'},
      ),
      QuestionOption(
        val: 'multiday', icon: '🏔️',
        title: {'it': 'Più giorni (3-4 notti)', 'en': 'Multi-day trek (3-4 nights)', 'fr': 'Plusieurs jours (3-4 nuits)', 'es': 'Varios días (3-4 noches)'},
        sub: {'it': 'Trekking a tappe di media durata', 'en': 'Medium-length multi-stage trek', 'fr': 'Trekking à étapes de moyenne durée', 'es': 'Trekking por etapas de media duración'},
      ),
      QuestionOption(
        val: 'cammino', icon: '🐚',
        title: {'it': 'Cammino (5+ notti)', 'en': 'Long-distance trail (5+ nights)', 'fr': 'Grand chemin / Thru-hike (5+ nuits)', 'es': 'Gran recorrido / Camino (5+ noches)'},
        sub: {'it': 'Lunga percorrenza a tappe, di paese in paese', 'en': 'Multi-stage long-distance route, village to village', 'fr': 'Itinéraire à étapes au long cours, de village en village', 'es': 'Ruta larga por etapas, de pueblo en pueblo'},
      ),
    ],
  ),
  QuestionDef(
    id: 'alloggio',
    title: {'it': 'Dove dormirai?', 'en': 'Where will you sleep?', 'fr': 'Où allez-vous dormir ?', 'es': '¿Dónde vas a dormir?'},
    desc: {'it': 'Seleziona la tipologia di pernottamento principale.', 'en': 'Select your main overnight accommodation.', 'fr': 'Sélectionnez votre type d\'hébergement principal.', 'es': 'Selecciona el tipo de alojamiento principal.'},
    options: [
      QuestionOption(
        val: 'rifugio', icon: '🏡',
        title: {'it': 'Rifugio / Ostello / Struttura gestita', 'en': 'Hut / Hostel / Managed facility', 'fr': 'Refuge / Auberge / Gîte d\'étape', 'es': 'Refugio / Albergue / Alojamiento gestionado'},
        sub: {'it': 'Struttura al chiuso con letti e servizi', 'en': 'Indoor accommodation with beds and facilities', 'fr': 'Hébergement intérieur avec lits et services', 'es': 'Alojamiento interior con camas y servicios'},
      ),
      QuestionOption(
        val: 'bivacco', icon: '🛖',
        title: {'it': 'Bivacco non gestito', 'en': 'Unstaffed bivouac', 'fr': 'Bivouac non gardé / Abri', 'es': 'Vivac / Refugio libre'},
        sub: {'it': 'Ricovero incustodito senza servizi', 'en': 'Unattended shelter without services', 'fr': 'Abri non gardé sans services', 'es': 'Refugio libre sin servicios'},
      ),
      QuestionOption(
        val: 'tenda', icon: '⛺',
        title: {'it': 'Tenda', 'en': 'Tent', 'fr': 'Tente', 'es': 'Tienda de campaña'},
        sub: {'it': 'Pernottamento in completa autonomia', 'en': 'Full camping self-sufficiency', 'fr': 'En autonomie complète sous tente', 'es': 'En total autonomía de acampada'},
      ),
    ],
  ),
  QuestionDef(
    id: 'clima',
    title: {'it': 'Che clima è previsto?', 'en': 'What weather is expected?', 'fr': 'Quel temps est prévu ?', 'es': '¿Qué clima se espera?'},
    desc: {'it': 'Condizioni termiche e ambientali lungo il percorso.', 'en': 'Expected temperature and ground conditions.', 'fr': 'Conditions thermiques et environnementales.', 'es': 'Condiciones térmicas y del entorno.'},
    options: [
      QuestionOption(
        val: 'caldo', icon: '☀️',
        title: {'it': 'Caldo / Soleggiato', 'en': 'Warm / Sunny', 'fr': 'Chaud / Ensoleillé', 'es': 'Cálido / Soleado'},
        sub: {'it': 'Temperature estive e sole', 'en': 'Summer temperatures and strong sun', 'fr': 'Températures estivales et soleil', 'es': 'Temperaturas de verano y sol'},
      ),
      QuestionOption(
        val: 'temperato', icon: '⛅',
        title: {'it': 'Temperato / Variabile', 'en': 'Mild / Variable', 'fr': 'Tempéré / Variable', 'es': 'Templado / Variable'},
        sub: {'it': 'Mezze stagioni o meteo incerto', 'en': 'Spring/Autumn or changeable weather', 'fr': 'Mi-saison ou météo changeante', 'es': 'Entretiempo o clima variable'},
      ),
      QuestionOption(
        val: 'freddo', icon: '🧥',
        title: {'it': 'Freddo intenso', 'en': 'Cold (no snow)', 'fr': 'Froid intense (sans neige)', 'es': 'Frío intenso (sin nieve)'},
        sub: {'it': 'Basse temperature senza neve', 'en': 'Low temperatures without snow', 'fr': 'Basses températures sans neige', 'es': 'Bajas temperaturas sin nieve'},
      ),
      QuestionOption(
        val: 'neve', icon: '❄️',
        title: {'it': 'Ambiente innevato / Ghiacciato', 'en': 'Snowy / Icy conditions', 'fr': 'Enneigé / Glacé', 'es': 'Nevado / Con hielo'},
        sub: {'it': 'Neve, ghiacciaio o terreno invernale', 'en': 'Snow, glacier or winter terrain', 'fr': 'Neige, glacier ou terrain hivernal', 'es': 'Nieve, glaciar o terreno invernal'},
      ),
    ],
  ),
  QuestionDef(
    id: 'percorso',
    title: {'it': 'Difficoltà tecnica del percorso?', 'en': 'Trail technical difficulty?', 'fr': 'Difficulté technique du parcours ?', 'es': '¿Dificultad técnica de la ruta?'},
    desc: {'it': 'Determina l\'attrezzatura tecnica di progressione.', 'en': 'Determines required technical progression gear.', 'fr': 'Détermine le matériel technique de progression.', 'es': 'Determina el equipo técnico de progresión.'},
    options: [
      QuestionOption(
        val: 'escursionistico', icon: '🥾',
        title: {'it': 'Sentiero escursionistico', 'en': 'Hiking trail', 'fr': 'Sentier de randonnée', 'es': 'Sendero de excursionismo'},
        sub: {'it': 'Livello T, E o EE (solo camminata)', 'en': 'Standard walking trail (no harness)', 'fr': 'Marche sur sentier uniquement', 'es': 'Sendero de marcha normal'},
      ),
      QuestionOption(
        val: 'ferrata', icon: '🧗',
        title: {'it': 'Via Ferrata / Sentiero attrezzato', 'en': 'Via Ferrata / Equipped trail', 'fr': 'Via Ferrata / Sentier équipé', 'es': 'Vía Ferrata / Sendero equipado'},
        sub: {'it': 'Cavi metallici, scale e verticalità', 'en': 'Steel cables, ladders and exposure', 'fr': 'Câbles, échelles et verticalité', 'es': 'Cables de acero, grapas y verticalidad'},
      ),
      QuestionOption(
        val: 'alpinistico', icon: '⛏️',
        title: {'it': 'Percorso Alpinistico', 'en': 'Mountaineering route', 'fr': 'Parcours d\'alpinisme', 'es': 'Ruta de alpinismo'},
        sub: {'it': 'Alta quota, creste o progressione su corda', 'en': 'High altitude, ridges or roped travel', 'fr': 'Haute montagne, crêtes ou corde', 'es': 'Alta montaña, aristas o cuerda'},
      ),
    ],
  ),
  QuestionDef(
    id: 'acqua',
    title: {'it': 'Disponibilità d\'acqua lungo il percorso?', 'en': 'Water availability along the route?', 'fr': 'Disponibilité en eau sur le parcours ?', 'es': '¿Disponibilidad de agua en el recorrido?'},
    desc: {'it': 'Fontane, punti di ristoro o sorgenti potabili certe.', 'en': 'Fountains, refreshment points or reliable sources.', 'fr': 'Fontaines, points d\'eau ou sources potables sûres.', 'es': 'Fuentes, puntos de apoyo o manantiales potables.'},
    options: [
      QuestionOption(
        val: 'presente', icon: '💧',
        title: {'it': 'Presente', 'en': 'Available and frequent', 'fr': 'Présente et fréquente', 'es': 'Presente y frecuente'},
        sub: {'it': 'Punti d\'acqua regolari lungo la traccia', 'en': 'Regular water points along the route', 'fr': 'Points d\'eau réguliers sur le sentier', 'es': 'Puntos de agua seguros en la ruta'},
      ),
      QuestionOption(
        val: 'assente', icon: '🚰',
        title: {'it': 'Assente o incerta', 'en': 'Scarce or uncertain', 'fr': 'Absente ou incertaine', 'es': 'Ausente o incierta'},
        sub: {'it': 'Nessun punto d\'acqua garantito sul tracciato', 'en': 'No guaranteed water sources on trail', 'fr': 'Aucun point d\'eau garanti sur le tracé', 'es': 'Sin puntos de agua garantizados'},
      ),
    ],
  ),
  QuestionDef(
    id: 'pasti',
    title: {'it': 'Come gestirai i pasti?', 'en': 'How will you manage meals?', 'fr': 'Comment gérez-vous les repas ?', 'es': '¿Cómo gestionarás las comidas?'},
    desc: {'it': 'Modalità di alimentazione durante l\'uscita.', 'en': 'Food and cooking setup for your trip.', 'fr': 'Organisation des repas pendant la sortie.', 'es': 'Modalidad de alimentación en la salida.'},
    options: [
      QuestionOption(
        val: 'struttura', icon: '🍽️',
        title: {'it': 'In struttura (Rifugio / Ristorante)', 'en': 'At hut / restaurant', 'fr': 'En refuge / restaurant', 'es': 'En refugio / restaurante'},
        sub: {'it': 'Pasti caldi nei punti di ristoro lungo il percorso', 'en': 'Hot meals at refreshment points along the route', 'fr': 'Repas chauds dans les points d\'étape', 'es': 'Comidas calientes en los puntos de apoyo'},
      ),
      QuestionOption(
        val: 'sacco', icon: '🥪',
        title: {'it': 'Al sacco', 'en': 'Packed meals', 'fr': 'Pique-nique (Repas froids)', 'es': 'Comida de picnic'},
        sub: {'it': 'Cibo pronto a freddo (panini, barrette)', 'en': 'Ready-to-eat cold food & sandwiches', 'fr': 'Sandwichs et nourriture prête', 'es': 'Bocadillos y comida lista para comer'},
      ),
      QuestionOption(
        val: 'cucina', icon: '🍲',
        title: {'it': 'Cucina da campo', 'en': 'Camp cooking (stove)', 'fr': 'Cuisine de bivouac (Réchaud)', 'es': 'Cocina de acampada (Hornillo)'},
        sub: {'it': 'Preparazione autonoma di pasti caldi', 'en': 'Self-sufficient hot meal preparation', 'fr': 'Préparation autonome de repas chauds', 'es': 'Preparación autónoma de comidas calientes'},
      ),
    ],
  ),
];

class MasterItem {
  final String id;
  final String cat;
  final bool Function(Map<String, String> a) cond;
  final Map<String, String> names;
  const MasterItem({required this.id, required this.cat, required this.cond, required this.names});
}

bool _always(Map<String, String> a) => true;

final List<MasterItem> kMasterItems = [
  // CAT-1: Abbigliamento (21 voci)
  MasterItem(id: 'ITEM-001', cat: 'CAT-1', cond: _always, names: {'it': 'Scarpe da trekking', 'en': 'Hiking shoes / boots', 'fr': 'Chaussures de randonnée', 'es': 'Zapatillas / Botas de trekking'}),
  MasterItem(id: 'ITEM-002', cat: 'CAT-1', cond: _always, names: {'it': 'Calze da trekking', 'en': 'Hiking socks', 'fr': 'Chaussettes de randonnée', 'es': 'Calcetines de senderismo'}),
  MasterItem(id: 'ITEM-003', cat: 'CAT-1', cond: _always, names: {'it': 'Maglia tecnica traspirante', 'en': 'Breathable base layer shirt', 'fr': 'T-shirt technique respirant', 'es': 'Camiseta técnica transpirable'}),
  MasterItem(id: 'ITEM-004', cat: 'CAT-1', cond: _always, names: {'it': 'Maglia di ricambio', 'en': 'Spare base layer shirt', 'fr': 'T-shirt de rechange', 'es': 'Camiseta de repuesto'}),
  MasterItem(id: 'ITEM-005', cat: 'CAT-1', cond: _always, names: {'it': 'Strato termico (pile o micropile)', 'en': 'Mid-layer fleece', 'fr': 'Polaire ou micro-polaire', 'es': 'Forro polar (capa intermedia)'}),
  MasterItem(id: 'ITEM-006', cat: 'CAT-1', cond: _always, names: {'it': 'Guscio impermeabile / antivento', 'en': 'Waterproof / windproof hardshell jacket', 'fr': 'Veste imperméable / coupe-vent (Hardshell)', 'es': 'Chaqueta impermeable / cortavientos (Hardshell)'}),
  MasterItem(id: 'ITEM-007', cat: 'CAT-1', cond: _always, names: {'it': 'Pantaloni da trekking', 'en': 'Hiking pants', 'fr': 'Pantalon de randonnée', 'es': 'Pantalones de senderismo'}),
  MasterItem(id: 'ITEM-008', cat: 'CAT-1', cond: (a) => a['durata'] != 'giornata', names: {'it': 'Ricambi intimo e calze', 'en': 'Spare underwear and socks', 'fr': 'Sous-vêtements et chaussettes de rechange', 'es': 'Ropa interior y calcetines de repuesto'}),
  MasterItem(id: 'ITEM-009', cat: 'CAT-1', cond: (a) => a['clima'] == 'caldo', names: {'it': 'Cappellino per il sole', 'en': 'Sun hat / cap', 'fr': 'Casquette / Chapeau de soleil', 'es': 'Gorra / Sombrero para el sol'}),
  MasterItem(id: 'ITEM-010', cat: 'CAT-1', cond: (a) => a['clima'] == 'temperato', names: {'it': 'Guanti leggeri', 'en': 'Lightweight gloves', 'fr': 'Gants légers', 'es': 'Guantes ligeros'}),
  MasterItem(id: 'ITEM-011', cat: 'CAT-1', cond: (a) => a['clima'] == 'temperato', names: {'it': 'Scaldacollo leggero', 'en': 'Lightweight neck gaiter', 'fr': 'Tour de cou léger', 'es': 'Braga de cuello ligera'}),
  MasterItem(id: 'ITEM-012', cat: 'CAT-1', cond: (a) => a['clima'] == 'freddo' || a['clima'] == 'neve', names: {'it': 'Piumino o giacca termica pesante', 'en': 'Down jacket / Heavy insulated jacket', 'fr': 'Doudoune / Veste thermique chaude', 'es': 'Chaqueta de plumas / Abrigo térmico'}),
  MasterItem(id: 'ITEM-013', cat: 'CAT-1', cond: (a) => a['clima'] == 'freddo' || a['clima'] == 'neve', names: {'it': 'Maglia e calzamaglia termica', 'en': 'Thermal base layer (top and bottom)', 'fr': 'Sous-vêtements thermiques (haut et collant)', 'es': 'Camiseta y mallas térmicas'}),
  MasterItem(id: 'ITEM-014', cat: 'CAT-1', cond: (a) => a['clima'] == 'freddo' || a['clima'] == 'neve', names: {'it': 'Guanti caldi', 'en': 'Warm winter gloves', 'fr': 'Gants chauds d\'hiver', 'es': 'Guantes térmicos cálidos'}),
  MasterItem(id: 'ITEM-015', cat: 'CAT-1', cond: (a) => a['clima'] == 'freddo' || a['clima'] == 'neve', names: {'it': 'Berretto invernale', 'en': 'Warm beanie / Winter hat', 'fr': 'Bonnet d\'hiver', 'es': 'Gorro de invierno'}),
  MasterItem(id: 'ITEM-016', cat: 'CAT-1', cond: (a) => a['clima'] == 'freddo' || a['clima'] == 'neve', names: {'it': 'Scaldacollo', 'en': 'Thermal neck gaiter', 'fr': 'Tour de cou chaud', 'es': 'Braga de cuello térmica'}),
  MasterItem(id: 'ITEM-017', cat: 'CAT-1', cond: (a) => a['clima'] == 'neve', names: {'it': 'Ghette', 'en': 'Gaiters', 'fr': 'Guêtres', 'es': 'Polainas'}),
  MasterItem(id: 'ITEM-018', cat: 'CAT-1', cond: (a) => a['durata'] == 'cammino', names: {'it': 'Secondo cambio (intimo, calze e maglia)', 'en': 'Second spare set (underwear, socks, shirt)', 'fr': 'Deuxième change (sous-vêtements, chaussettes, t-shirt)', 'es': 'Segundo cambio (ropa interior, calcetines y camiseta)'}),
  MasterItem(id: 'ITEM-019', cat: 'CAT-1', cond: (a) => a['durata'] == 'cammino', names: {'it': 'Pantaloni di ricambio', 'en': 'Spare hiking pants', 'fr': 'Pantalon de rechange', 'es': 'Pantalones de repuesto'}),
  MasterItem(id: 'ITEM-020', cat: 'CAT-1', cond: (a) => a['durata'] == 'cammino', names: {'it': 'Strato termico (pile) di ricambio', 'en': 'Spare fleece mid-layer', 'fr': 'Polaire de rechange', 'es': 'Forro polar de repuesto'}),
  MasterItem(id: 'ITEM-021', cat: 'CAT-1', cond: (a) => a['durata'] == 'cammino', names: {'it': 'Sandali da trekking / riposo', 'en': 'Camp / recovery sandals', 'fr': 'Sandales de repos / randonnée', 'es': 'Sandalias de descanso / trekking'}),

  // CAT-2: Accessori (15 voci)
  MasterItem(id: 'ITEM-022', cat: 'CAT-2', cond: _always, names: {'it': 'Powerbank e cavo di ricarica', 'en': 'Powerbank and charging cable', 'fr': 'Batterie externe (Powerbank) et câble', 'es': 'Batería externa (Powerbank) y cable'}),
  MasterItem(id: 'ITEM-023', cat: 'CAT-2', cond: _always, names: {'it': 'Sacchetto per i rifiuti', 'en': 'Trash bag', 'fr': 'Sac poubelle', 'es': 'Bolsa para residuos'}),
  MasterItem(id: 'ITEM-024', cat: 'CAT-2', cond: _always, names: {'it': 'Documenti personali e tessera sanitaria', 'en': 'ID and health insurance card', 'fr': 'Pièce d\'identité et carte vitale / santé', 'es': 'Documento de identidad y tarjeta sanitaria'}),
  MasterItem(id: 'ITEM-025', cat: 'CAT-2', cond: _always, names: {'it': 'Contanti', 'en': 'Cash', 'fr': 'Argent liquide (Espèces)', 'es': 'Dinero en efectivo'}),
  MasterItem(id: 'ITEM-026', cat: 'CAT-2', cond: _always, names: {'it': 'Occhiali da sole', 'en': 'Sunglasses', 'fr': 'Lunettes de soleil', 'es': 'Gafas de sol'}),
  MasterItem(id: 'ITEM-027', cat: 'CAT-2', cond: _always, names: {'it': 'Stick labbra con filtro UV', 'en': 'UV lip balm', 'fr': 'Stick à lèvres protection UV', 'es': 'Protector labial con filtro UV'}),
  MasterItem(id: 'ITEM-028', cat: 'CAT-2', cond: _always, names: {'it': 'Bastoncini da trekking', 'en': 'Trekking poles', 'fr': 'Bâtons de randonnée', 'es': 'Bastones de trekking'}),
  MasterItem(id: 'ITEM-029', cat: 'CAT-2', cond: (a) => a['durata'] != 'giornata' && (a['alloggio'] == 'bivacco' || a['alloggio'] == 'tenda'), names: {'it': 'Ago e filo', 'en': 'Needle and thread', 'fr': 'Aiguille et fil de couture', 'es': 'Aguja e hilo'}),
  MasterItem(id: 'ITEM-030', cat: 'CAT-2', cond: (a) => a['alloggio'] == 'rifugio', names: {'it': 'Tappi per le orecchie', 'en': 'Earplugs', 'fr': 'Bouchons d\'oreilles', 'es': 'Tapones para los oídos'}),
  MasterItem(id: 'ITEM-031', cat: 'CAT-2', cond: (a) => a['alloggio'] == 'rifugio', names: {'it': 'Tessera CAI', 'en': 'Alpine Club membership card (CAI)', 'fr': 'Carte Club Alpin', 'es': 'Carné de federado / Club Alpino'}),
  MasterItem(id: 'ITEM-032', cat: 'CAT-2', cond: (a) => a['clima'] == 'caldo' || a['clima'] == 'neve', names: {'it': 'Crema solare', 'en': 'Sunscreen', 'fr': 'Crème solaire', 'es': 'Crema solar'}),
  MasterItem(id: 'ITEM-033', cat: 'CAT-2', cond: (a) => a['durata'] != 'giornata', names: {'it': 'Caricabatterie', 'en': 'Wall charger', 'fr': 'Chargeur secteur', 'es': 'Cargador de pared'}),
  MasterItem(id: 'ITEM-034', cat: 'CAT-2', cond: (a) => a['durata'] == 'cammino', names: {'it': 'Cordino e spille da balia', 'en': 'Thin cord and safety pins', 'fr': 'Cordelette et épingles à nourrice', 'es': 'Cordino e imperdibles'}),
  MasterItem(id: 'ITEM-035', cat: 'CAT-2', cond: (a) => a['durata'] == 'cammino', names: {'it': 'Buste impermeabili / Sacchetti ermetici', 'en': 'Dry bags / Waterproof ziplock bags', 'fr': 'Sacs étanches / Sachets zip', 'es': 'Bolsas estancas / Bolsas herméticas'}),
  MasterItem(id: 'ITEM-036', cat: 'CAT-2', cond: (a) => a['durata'] == 'cammino', names: {'it': 'Credenziale del Pellegrino', 'en': 'Pilgrim\'s Credential / Passport', 'fr': 'Crédenciale du Pèlerin', 'es': 'Credencial del Peregrino'}),

  // CAT-3: Attrezzatura Tecnica (10 voci)
  MasterItem(id: 'ITEM-037', cat: 'CAT-3', cond: _always, names: {'it': 'Zaino da escursionismo', 'en': 'Hiking backpack', 'fr': 'Sac à dos de randonnée', 'es': 'Mochila de senderismo'}),
  MasterItem(id: 'ITEM-038', cat: 'CAT-3', cond: _always, names: {'it': 'Coprizaino antipioggia', 'en': 'Backpack rain cover', 'fr': 'Housse de pluie pour sac à dos', 'es': 'Cubremochila impermeable'}),
  MasterItem(id: 'ITEM-039', cat: 'CAT-3', cond: (a) => a['clima'] == 'neve' && a['percorso'] == 'escursionistico', names: {'it': 'Ciaspe o ramponcini', 'en': 'Snowshoes or microspikes', 'fr': 'Raquettes à neige ou mini-crampons', 'es': 'Raquetas de nieve o crampones ligeros'}),
  MasterItem(id: 'ITEM-040', cat: 'CAT-3', cond: (a) => a['percorso'] == 'ferrata' || a['percorso'] == 'alpinistico', names: {'it': 'Casco da alpinismo / arrampicata', 'en': 'Mountaineering / climbing helmet', 'fr': 'Casque d\'alpinisme / escalade', 'es': 'Casco de alpinismo / escalada'}),
  MasterItem(id: 'ITEM-041', cat: 'CAT-3', cond: (a) => a['percorso'] == 'ferrata' || a['percorso'] == 'alpinistico', names: {'it': 'Imbrago', 'en': 'Climbing harness', 'fr': 'Baudrier (Harnais)', 'es': 'Arnés'}),
  MasterItem(id: 'ITEM-042', cat: 'CAT-3', cond: (a) => a['percorso'] == 'ferrata', names: {'it': 'Set da ferrata omologato', 'en': 'Certified Via Ferrata lanyard set', 'fr': 'Longe de Via Ferrata homologuée', 'es': 'Disipador de Vía Ferrata homologado'}),
  MasterItem(id: 'ITEM-043', cat: 'CAT-3', cond: (a) => a['percorso'] == 'ferrata', names: {'it': 'Guanti da ferrata', 'en': 'Via Ferrata gloves', 'fr': 'Gants de Via Ferrata', 'es': 'Guantes para Vía Ferrata'}),
  MasterItem(id: 'ITEM-044', cat: 'CAT-3', cond: (a) => a['percorso'] == 'alpinistico' && a['clima'] == 'neve', names: {'it': 'Kit progressione neve (piccozza e ramponi)', 'en': 'Snow progression kit (ice axe & crampons)', 'fr': 'Kit progression neige (piolet et crampons)', 'es': 'Kit progresión nieve (piolet y crampones)'}),
  MasterItem(id: 'ITEM-045', cat: 'CAT-3', cond: (a) => a['percorso'] == 'alpinistico', names: {'it': 'Corda, moschettoni e kit d\'assicurazione', 'en': 'Rope, carabiners & belay kit', 'fr': 'Corde, mousquetons et kit d\'assurage', 'es': 'Cuerda, mosquetones y kit de aseguramiento'}),
  MasterItem(id: 'ITEM-046', cat: 'CAT-3', cond: (a) => a['clima'] == 'neve', names: {'it': 'Kit Neve (ARTVA, pala, sonda)', 'en': 'Avalanche Safety Kit (Transceiver, shovel, probe)', 'fr': 'Kit Sécurité Neige (DVA, pelle, sonde)', 'es': 'Kit de Nieve (ARVA, pala, sonda)'}),

  // CAT-4: Cibo e Idratazione (13 voci)
  MasterItem(id: 'ITEM-047', cat: 'CAT-4', cond: _always, names: {'it': 'Borraccia d\'acqua', 'en': 'Water bottle / Hydration bladder', 'fr': 'Gourde ou poche à eau', 'es': 'Cantimplora o bolsa de hidratación'}),
  MasterItem(id: 'ITEM-048', cat: 'CAT-4', cond: _always, names: {'it': 'Snack energetici', 'en': 'Energy snacks / trail mix', 'fr': 'Barres et encas énergétiques', 'es': 'Snacks y barritas energéticas'}),
  MasterItem(id: 'ITEM-049', cat: 'CAT-4', cond: (a) => a['pasti'] == 'sacco', names: {'it': 'Pasti al sacco', 'en': 'Packed meals / sandwiches', 'fr': 'Pique-nique / Repas froids', 'es': 'Comida de picnic / bocadillos'}),
  MasterItem(id: 'ITEM-050', cat: 'CAT-4', cond: (a) => a['durata'] != 'giornata' && (a['alloggio'] == 'bivacco' || a['alloggio'] == 'tenda' || a['pasti'] == 'cucina'), names: {'it': 'Colazione', 'en': 'Breakfast food', 'fr': 'Petit-déjeuner', 'es': 'Desayuno'}),
  MasterItem(id: 'ITEM-051', cat: 'CAT-4', cond: (a) => a['pasti'] == 'cucina', names: {'it': 'Pasti da cucinare / liofilizzati', 'en': 'Freeze-dried / cookable meals', 'fr': 'Repas lyophilisés / à cuisiner', 'es': 'Comida liofilizada / para cocinar'}),
  MasterItem(id: 'ITEM-052', cat: 'CAT-4', cond: (a) => a['pasti'] == 'cucina', names: {'it': 'Fornelletto da campeggio', 'en': 'Camping stove', 'fr': 'Réchaud de randonnée', 'es': 'Hornillo de acampada'}),
  MasterItem(id: 'ITEM-053', cat: 'CAT-4', cond: (a) => a['pasti'] == 'cucina', names: {'it': 'Cartuccia del gas', 'en': 'Gas canister', 'fr': 'Cartouche de gaz', 'es': 'Cartucho de gas'}),
  MasterItem(id: 'ITEM-054', cat: 'CAT-4', cond: (a) => a['pasti'] == 'cucina', names: {'it': 'Gavetta e posate', 'en': 'Cookset (pot) and cutlery', 'fr': 'Popote et couverts', 'es': 'Cazuela (marmita) y cubiertos'}),
  MasterItem(id: 'ITEM-055', cat: 'CAT-4', cond: (a) => a['pasti'] == 'cucina', names: {'it': 'Tazza', 'en': 'Camp mug / cup', 'fr': 'Tasse / Mug', 'es': 'Taza'}),
  MasterItem(id: 'ITEM-056', cat: 'CAT-4', cond: (a) => a['pasti'] == 'cucina', names: {'it': 'Spugnetta e sapone biodegradabile', 'en': 'Sponge and biodegradable soap', 'fr': 'Éponge et savon biodégradable', 'es': 'Esponja y jabón biodegradable'}),
  MasterItem(id: 'ITEM-057', cat: 'CAT-4', cond: (a) => a['acqua'] == 'assente', names: {'it': 'Scorta d\'acqua extra', 'en': 'Extra water supply', 'fr': 'Réserve d\'eau supplémentaire', 'es': 'Reserva de agua extra'}),
  MasterItem(id: 'ITEM-058', cat: 'CAT-4', cond: (a) => a['acqua'] == 'assente', names: {'it': 'Filtro per l\'acqua o pastiglie potabilizzanti', 'en': 'Water filter or purification tablets', 'fr': 'Filtre à eau ou pastilles purifiantes', 'es': 'Filtro de agua o pastillas potabilizadoras'}),
  MasterItem(id: 'ITEM-059', cat: 'CAT-4', cond: (a) => a['clima'] == 'caldo', names: {'it': 'Sali minerali', 'en': 'Electrolytes / Mineral salts', 'fr': 'Électrolytes / Sels minéraux', 'es': 'Sales minerales / Electrolitos'}),

  // CAT-5: Igiene e Pernottamento (12 voci)
  MasterItem(id: 'ITEM-060', cat: 'CAT-5', cond: _always, names: {'it': 'Fazzoletti di carta', 'en': 'Paper tissues / Toilet paper', 'fr': 'Mouchoirs en papier', 'es': 'Pañuelos de papel'}),
  MasterItem(id: 'ITEM-061', cat: 'CAT-5', cond: (a) => a['durata'] != 'giornata', names: {'it': 'Kit igiene personale', 'en': 'Personal toiletry kit', 'fr': 'Trousse de toilette', 'es': 'Kit de higiene personal'}),
  MasterItem(id: 'ITEM-062', cat: 'CAT-5', cond: (a) => a['durata'] != 'giornata', names: {'it': 'Spazzolino e dentifricio', 'en': 'Toothbrush and toothpaste', 'fr': 'Brosse à dents et dentifrice', 'es': 'Cepillo y pasta de dientes'}),
  MasterItem(id: 'ITEM-063', cat: 'CAT-5', cond: (a) => a['durata'] != 'giornata', names: {'it': 'Asciugamano in microfibra', 'en': 'Microfiber towel', 'fr': 'Serviette en microfibre', 'es': 'Toalla de microfibra'}),
  MasterItem(id: 'ITEM-064', cat: 'CAT-5', cond: (a) => a['alloggio'] == 'rifugio', names: {'it': 'Sacco lenzuolo', 'en': 'Sleeping bag liner', 'fr': 'Drap de sac', 'es': 'Saco sábana'}),
  MasterItem(id: 'ITEM-065', cat: 'CAT-5', cond: (a) => a['alloggio'] == 'bivacco' || a['alloggio'] == 'tenda' || (a['alloggio'] == 'rifugio' && a['clima'] != 'caldo'), names: {'it': 'Sacco a pelo', 'en': 'Sleeping bag', 'fr': 'Sac de couchage (duvet)', 'es': 'Saco de dormir'}),
  MasterItem(id: 'ITEM-066', cat: 'CAT-5', cond: (a) => a['alloggio'] == 'rifugio' && a['durata'] != 'cammino', names: {'it': 'Ciabatte', 'en': 'Hut slippers / flip-flops', 'fr': 'Claquettes / Chaussons de refuge', 'es': 'Chanclas / Zapatillas de refugio'}),
  MasterItem(id: 'ITEM-067', cat: 'CAT-5', cond: (a) => a['alloggio'] == 'bivacco' || a['alloggio'] == 'tenda', names: {'it': 'Materassino isolante', 'en': 'Sleeping pad / mat', 'fr': 'Matelas isolant', 'es': 'Esterilla aislante'}),
  MasterItem(id: 'ITEM-068', cat: 'CAT-5', cond: (a) => a['alloggio'] == 'bivacco' || a['alloggio'] == 'tenda', names: {'it': 'Cuscino gonfiabile', 'en': 'Inflatable pillow', 'fr': 'Oreiller gonflable', 'es': 'Almohada inflable'}),
  MasterItem(id: 'ITEM-069', cat: 'CAT-5', cond: (a) => a['alloggio'] == 'tenda', names: {'it': 'Tenda da camping', 'en': 'Trekking tent', 'fr': 'Tente de randonnée', 'es': 'Tienda de campaña'}),
  MasterItem(id: 'ITEM-070', cat: 'CAT-5', cond: (a) => a['durata'] == 'cammino', names: {'it': 'Sapone di Marsiglia', 'en': 'Marseille soap bar', 'fr': 'Savon de Marseille', 'es': 'Jabón de Marsella'}),
  MasterItem(id: 'ITEM-071', cat: 'CAT-5', cond: (a) => a['durata'] == 'cammino', names: {'it': 'Crema anti-sfregamento / Vaselina', 'en': 'Anti-chafing cream / Vaseline', 'fr': 'Crème anti-frottements / Vaseline', 'es': 'Crema antifricción / Vaselina'}),

  // CAT-6: Sicurezza e Orientamento (10 voci)
  MasterItem(id: 'ITEM-072', cat: 'CAT-6', cond: _always, names: {'it': 'Kit di primo soccorso', 'en': 'First aid kit', 'fr': 'Trousse de premiers secours', 'es': 'Botiquín de primeros auxilios'}),
  MasterItem(id: 'ITEM-073', cat: 'CAT-6', cond: (a) => a['durata'] == 'multiday' || a['durata'] == 'cammino', names: {'it': 'Cerotti anti-vesciche', 'en': 'Blister plasters (hydrocolloid)', 'fr': 'Pansements ampoules (double peau)', 'es': 'Apósitos para ampollas'}),
  MasterItem(id: 'ITEM-074', cat: 'CAT-6', cond: _always, names: {'it': 'Eventuali medicinali personali', 'en': 'Personal medications', 'fr': 'Médicaments personnels', 'es': 'Medicamentos personales'}),
  MasterItem(id: 'ITEM-075', cat: 'CAT-6', cond: _always, names: {'it': 'Telo termico d\'emergenza', 'en': 'Emergency space blanket', 'fr': 'Couverture de survie', 'es': 'Manta térmica de emergencia'}),
  MasterItem(id: 'ITEM-076', cat: 'CAT-6', cond: _always, names: {'it': 'Torcia frontale', 'en': 'Headlamp', 'fr': 'Lampe frontale', 'es': 'Linterna frontal'}),
  MasterItem(id: 'ITEM-077', cat: 'CAT-6', cond: _always, names: {'it': 'Fischietto d\'emergenza', 'en': 'Emergency whistle', 'fr': 'Sifflet de secours', 'es': 'Silbato de emergencia'}),
  MasterItem(id: 'ITEM-078', cat: 'CAT-6', cond: _always, names: {'it': 'Coltellino multiuso', 'en': 'Multi-tool / Pocket knife', 'fr': 'Couteau multifonction / Couteau suisse', 'es': 'Navaja multiusos'}),
  MasterItem(id: 'ITEM-079', cat: 'CAT-6', cond: _always, names: {'it': 'Accendino', 'en': 'Lighter', 'fr': 'Briquet', 'es': 'Encendedor / Mechero'}),
  MasterItem(id: 'ITEM-080', cat: 'CAT-6', cond: _always, names: {'it': 'Mappa cartacea o traccia GPX offline', 'en': 'Paper map or offline GPX track', 'fr': 'Carte papier ou trace GPX hors-ligne', 'es': 'Mapa en papel o track GPX sin conexión'}),
  MasterItem(id: 'ITEM-081', cat: 'CAT-6', cond: _always, names: {'it': 'Telefono cellulare', 'en': 'Mobile phone', 'fr': 'Téléphone portable', 'es': 'Teléfono móvil'}),
];

// ============================================================================
// 5. MODELLI DATI CON SERIALIZZAZIONE JSON SICURA
// ============================================================================
class BackpackItem {
  String id;
  String cat;
  String? customName;
  String fallbackName;
  bool done;
  bool excluded;
  bool reminder;

  BackpackItem({
    required this.id,
    required this.cat,
    this.customName,
    required this.fallbackName,
    this.done = false,
    this.excluded = false,
    this.reminder = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cat': cat,
        'customName': customName,
        'fallbackName': fallbackName,
        'done': done,
        'excluded': excluded,
        'reminder': reminder,
      };

  factory BackpackItem.fromJson(Map<String, dynamic> j) => BackpackItem(
        id: j['id'] ?? '',
        cat: j['cat'] ?? 'CAT-1',
        customName: j['customName'],
        fallbackName: j['fallbackName'] ?? '',
        done: j['done'] == true,
        excluded: j['excluded'] == true,
        reminder: j['reminder'] == true,
      );
}

class BackpackModel {
  int schemaVersion;
  String id;
  int notifId; // ID numerico a 32-bit per le notifiche Android
  int createdAt;
  bool isDefaultName;
  String name;
  Map<String, String> answers;
  List<BackpackItem> items;
  String? reminderIso;

  BackpackModel({
    this.schemaVersion = 4,
    required this.id,
    required this.notifId,
    required this.createdAt,
    this.isDefaultName = true,
    this.name = '',
    required this.answers,
    required this.items,
    this.reminderIso,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'notifId': notifId,
        'createdAt': createdAt,
        'isDefaultName': isDefaultName,
        'name': name,
        'answers': answers,
        'items': items.map((e) => e.toJson()).toList(),
        'reminderIso': reminderIso,
      };

  factory BackpackModel.fromJson(Map<String, dynamic> j) {
    final rawAnswers = (j['answers'] as Map?) ?? {};
    final rawItems = (j['items'] as List?) ?? [];
    return BackpackModel(
      schemaVersion: j['schemaVersion'] ?? 4,
      id: j['id'] ?? 'BP_${DateTime.now().millisecondsSinceEpoch}',
      notifId: j['notifId'] ?? Random().nextInt(2000000000),
      createdAt: j['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      isDefaultName: j['isDefaultName'] ?? true,
      name: j['name'] ?? '',
      answers: rawAnswers.map((k, v) => MapEntry(k.toString(), v.toString())),
      items: rawItems
          .map((e) => BackpackItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      reminderIso: j['reminderIso'],
    );
  }
}

// ============================================================================
// 6. ILLUSTRAZIONE VETTORIALE ZAINO & MONTAGNE (CUSTOM PAINTER NATIVO)
// ============================================================================
class MountainBackpackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Montagne di sfondo
    final mtnPaint = Paint()..color = const Color(0xFFD6E3DA);
    final mtnPath = Path()
      ..moveTo(w * 0.1, h * 0.78)
      ..lineTo(w * 0.35, h * 0.40)
      ..lineTo(w * 0.53, h * 0.68)
      ..lineTo(w * 0.72, h * 0.31)
      ..lineTo(w * 0.93, h * 0.78)
      ..close();
    canvas.drawPath(mtnPath, mtnPaint);

    // Bastoncino da trekking inclinato
    final polePaint = Paint()
      ..color = const Color(0xFF7A8B7E)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.24, h * 0.22), Offset(w * 0.39, h * 0.84), polePaint);

    // Maniglia superiore zaino terracotta
    final handlePaint = Paint()
      ..color = AppColors.terracotta
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.43, h * 0.16, w * 0.14, h * 0.12),
      pi,
      pi,
      false,
      handlePaint,
    );

    // Corpo zaino verde foresta
    final bodyPaint = Paint()..color = AppColors.forestPrimary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.325, h * 0.27, w * 0.35, h * 0.48),
        const Radius.circular(18),
      ),
      bodyPaint,
    );

    // Calotta superiore e tasca inferiore
    final darkPaint = Paint()..color = AppColors.forestDark;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.24, w * 0.40, h * 0.15),
        const Radius.circular(14),
      ),
      darkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.36, h * 0.46, w * 0.28, h * 0.24),
        const Radius.circular(8),
      ),
      darkPaint,
    );

    // Cinghie terracotta verticali e fibbie
    final strapPaint = Paint()
      ..color = AppColors.terracotta
      ..strokeWidth = 3.2;
    canvas.drawLine(Offset(w * 0.41, h * 0.35), Offset(w * 0.41, h * 0.72), strapPaint);
    canvas.drawLine(Offset(w * 0.59, h * 0.35), Offset(w * 0.59, h * 0.72), strapPaint);

    final bucklePaint = Paint()..color = const Color(0xFFEAEFEA);
    for (final dx in [0.39, 0.57]) {
      for (final dy in [0.41, 0.60]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * dx, h * dy, w * 0.04, h * 0.05),
            const Radius.circular(2),
          ),
          bucklePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 7. APPLICAZIONE E STATO PRINCIPALE
// ============================================================================
class TrekkingChecklistApp extends StatelessWidget {
  const TrekkingChecklistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trekking Checklist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgStone,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.forestPrimary,
          primary: AppColors.forestPrimary,
          secondary: AppColors.terracotta,
        ),
      ),
      home: const MainShellPage(),
    );
  }
}

enum AppScreen { home, wizard, checklist, success }

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  String _lang = 'it';
  AppScreen _screen = AppScreen.home;
  List<BackpackModel> _backpacks = [];
  BackpackModel? _activeBackpack;
  String _activeCategory = 'CAT-1';
  bool _excludedExpanded = false;

  // Wizard state
  Map<String, String> _wizardAnswers = {};
  int _wizardStep = 0;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('trek_app_lang');
    if (savedLang != null && kUiStrings.containsKey(savedLang)) {
      _lang = savedLang;
    } else {
      final sysLang = WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
      _lang = kUiStrings.containsKey(sysLang) ? sysLang : 'it';
    }

    final rawList = prefs.getString('trek_backpacks_v4');
    if (rawList != null) {
      try {
        final decoded = jsonDecode(rawList) as List;
        _backpacks = decoded
            .map((e) => BackpackModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        _backpacks = [];
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveBackpacks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_backpacks.map((e) => e.toJson()).toList());
    await prefs.setString('trek_backpacks_v4', encoded);
  }

  Future<void> _setLanguage(String code) async {
    if (!kUiStrings.containsKey(code)) return;
    setState(() => _lang = code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trek_app_lang', code);
    if (_activeBackpack != null) {
      await _syncActiveBackpackNotification();
    }
  }

  String t(String key) => kUiStrings[_lang]?[key] ?? kUiStrings['it']![key] ?? key;

  String _formatShortDate(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    const months = {
      'it': ['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'],
      'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      'fr': ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'],
      'es': ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'],
    };
    final mList = months[_lang] ?? months['it']!;
    return '${dt.day} ${mList[dt.month - 1]}';
  }

  String _getBackpackDisplayName(BackpackModel bp) {
    if (bp.isDefaultName) {
      return '${t('defaultBpName')} ${_formatShortDate(bp.createdAt)}';
    }
    return bp.name.isNotEmpty ? bp.name : t('defaultBpName');
  }

  String _getItemDisplayName(BackpackItem item) {
    if (item.customName != null && item.customName!.isNotEmpty) {
      return item.customName!;
    }
    final master = kMasterItems.where((m) => m.id == item.id).firstOrNull;
    if (master != null) {
      return master.names[_lang] ?? master.names['it']!;
    }
    return item.fallbackName;
  }

  String _getCategoryDisplayName(String catId) {
    final cat = kCategories.where((c) => c.id == catId).firstOrNull;
    return cat != null ? (cat.names[_lang] ?? cat.names['it']!) : catId;
  }

  Future<void> _syncActiveBackpackNotification() async {
    final bp = _activeBackpack;
    if (bp == null) return;
    await NotificationService.instance.syncBackpackReminder(
      bp,
      _getBackpackDisplayName(bp),
      t('notifBodyIntro'),
      _getItemDisplayName,
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        backgroundColor: AppColors.forestDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        duration: const Duration(milliseconds: 2200),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    );
  }

  // ==========================================================================
  // WIZARD LOGICA
  // ==========================================================================
  List<QuestionDef> get _activeWizardQuestions {
    return kQuestions.where((q) {
      if (q.id == 'alloggio' && _wizardAnswers['durata'] == 'giornata') {
        return false;
      }
      return true;
    }).toList();
  }

  void _startWizard() {
    HapticFeedback.lightImpact();
    setState(() {
      _wizardAnswers = {};
      _wizardStep = 0;
      _isTransitioning = false;
      _screen = AppScreen.wizard;
    });
  }

  void _selectWizardOption(String qId, String val) {
    if (_isTransitioning) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isTransitioning = true;
      _wizardAnswers[qId] = val;
      if (_wizardAnswers['durata'] == 'giornata') {
        _wizardAnswers.remove('alloggio');
      }
    });

    Future.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      final questions = _activeWizardQuestions;
      if (_wizardStep + 1 < questions.length) {
        setState(() {
          _wizardStep++;
          _isTransitioning = false;
        });
      } else {
        _isTransitioning = false;
        _finalizeNewBackpack();
      }
    });
  }

  Future<void> _finalizeNewBackpack() async {
    final generatedItems = <BackpackItem>[];
    for (final m in kMasterItems) {
      if (m.cond(_wizardAnswers)) {
        generatedItems.add(BackpackItem(
          id: m.id,
          cat: m.cat,
          fallbackName: m.names['it']!,
        ));
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final newBp = BackpackModel(
      id: 'BP_$now',
      notifId: Random().nextInt(2000000000),
      createdAt: now,
      isDefaultName: true,
      name: '',
      answers: Map<String, String>.from(_wizardAnswers),
      items: generatedItems,
    );

    setState(() {
      _backpacks.insert(0, newBp);
      _activeBackpack = newBp;
      _activeCategory = 'CAT-1';
      _excludedExpanded = false;
      _screen = AppScreen.checklist;
    });
    await _saveBackpacks();
  }

  // ==========================================================================
  // AZIONI CHECKLIST & ARCHIVIO
  // ==========================================================================
  void _openBackpack(BackpackModel bp) {
    HapticFeedback.lightImpact();
    setState(() {
      _activeBackpack = bp;
      _activeCategory = 'CAT-1';
      _excludedExpanded = false;
      _screen = AppScreen.checklist;
    });
  }

  Future<void> _toggleDone(BackpackItem item) async {
    HapticFeedback.lightImpact();
    setState(() {
      item.done = !item.done;
    });
    await _saveBackpacks();
    await _syncActiveBackpackNotification();

    if (item.done && _activeBackpack != null) {
      final active = _activeBackpack!.items.where((i) => !i.excluded).toList();
      if (active.isNotEmpty && active.every((i) => i.done)) {
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 280), () {
          if (mounted) setState(() => _screen = AppScreen.success);
        });
      }
    }
  }

  Future<void> _toggleItemReminder(BackpackItem item) async {
    HapticFeedback.selectionClick();
    setState(() {
      item.reminder = !item.reminder;
    });
    await _saveBackpacks();
    await _syncActiveBackpackNotification();

    if (item.reminder && _activeBackpack?.reminderIso == null) {
      _openReminderSheet();
    } else {
      final name = _getItemDisplayName(item);
      _showToast('"$name" ${item.reminder ? t('toastAddedRem') : t('toastRemovedRem')}');
    }
  }

  Future<void> _excludeItem(BackpackItem item) async {
    HapticFeedback.lightImpact();
    setState(() {
      item.excluded = true;
    });
    await _saveBackpacks();
    await _syncActiveBackpackNotification();
    _showToast('"${_getItemDisplayName(item)}" ${t('toastExcluded')}');

    final active = _activeBackpack!.items.where((i) => !i.excluded).toList();
    if (active.isNotEmpty && active.every((i) => i.done)) {
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) setState(() => _screen = AppScreen.success);
      });
    }
  }

  Future<void> _restoreItem(BackpackItem item) async {
    HapticFeedback.lightImpact();
    setState(() {
      item.excluded = false;
    });
    await _saveBackpacks();
    await _syncActiveBackpackNotification();
    _showToast('"${_getItemDisplayName(item)}" ${t('toastRestored')}');
  }

  Future<void> _shareCurrentBackpack() async {
    final bp = _activeBackpack;
    if (bp == null) return;
    final bpTitle = _getBackpackDisplayName(bp);
    final sb = StringBuffer('🎒 *Trekking Checklist: $bpTitle*\n\n');

    for (final catObj in kCategories) {
      final items = bp.items.where((i) => i.cat == catObj.id && !i.excluded).toList();
      if (items.isNotEmpty) {
        sb.writeln('*${catObj.names[_lang] ?? catObj.names['it']}:*');
        for (final i in items) {
          sb.writeln('${i.done ? "✅" : "⬜"} ${_getItemDisplayName(i)}');
        }
        sb.writeln();
      }
    }
    await Share.share(sb.toString(), subject: bpTitle);
  }

  // ==========================================================================
  // BOTTOM SHEETS E DIALOGHI NATIVI
  // ==========================================================================
  void _openLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final langs = [
          ('it', '🇮🇹 Italiano'),
          ('en', '🇬🇧 English'),
          ('fr', '🇫🇷 Français'),
          ('es', '🇪🇸 Español'),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lingua / Language',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.forestDark),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.7,
                  physics: const NeverScrollableScrollPhysics(),
                  children: langs.map((l) {
                    final isSelected = l.$1 == _lang;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _setLanguage(l.$1);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.forestLight : AppColors.bgStone,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.forestPrimary : AppColors.borderSoft,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          l.$2,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openGuideSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final rows = [
          ('☑️', t('g1Title'), t('g1Desc')),
          ('🔔', t('g2Title'), t('g2Desc')),
          ('✕', t('g3Title'), t('g3Desc')),
          ('🔄', t('g4Title'), t('g4Desc')),
        ];
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('guideTitle'),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.forestDark),
                ),
                const SizedBox(height: 16),
                ...rows.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgStone,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.$1, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.forestDark)),
                                const SizedBox(height: 2),
                                Text(r.$3, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 6),
                _buildDisclaimerBox(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(t('btnGotIt'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text('© 2026 Matteo Palazzi', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPromptDialog({
    required String title,
    required String initialValue,
    required void Function(String val) onSave,
  }) {
    final ctrl = TextEditingController(text: initialValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 22,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: AppColors.forestDark)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgStone,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSoft),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(t('btnCancel')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final text = ctrl.text.trim();
                        Navigator.pop(ctx);
                        if (text.isNotEmpty) onSave(text);
                      },
                      child: Text(t('btnSave'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openConfirmDialog({
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.forestDark)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(t('btnCancel')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          onConfirm();
                        },
                        child: Text(t('btnConfirm'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openReminderSheet() {
    final bp = _activeBackpack;
    if (bp == null) return;

    DateTime selectedDt;
    if (bp.reminderIso != null && DateTime.tryParse(bp.reminderIso!) != null) {
      selectedDt = DateTime.parse(bp.reminderIso!);
    } else {
      final tom = DateTime.now().add(const Duration(days: 1));
      selectedDt = DateTime(tom.year, tom.month, tom.day, 6, 30);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final formatted =
                '${selectedDt.day.toString().padLeft(2, '0')}/${selectedDt.month.toString().padLeft(2, '0')}/${selectedDt.year}  ${selectedDt.hour.toString().padLeft(2, '0')}:${selectedDt.minute.toString().padLeft(2, '0')}';
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('modalRemTitle'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.forestDark)),
                    const SizedBox(height: 6),
                    Text(t('modalRemSub'), style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDt,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date == null || !ctx.mounted) return;
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(selectedDt),
                        );
                        if (time == null) return;
                        setSheetState(() {
                          selectedDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.bgStone,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSoft, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formatted, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            Text(t('btnPickDateTime'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.forestPrimary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          setState(() {
                            bp.reminderIso = selectedDt.toIso8601String();
                          });
                          await _saveBackpacks();
                          await _syncActiveBackpackNotification();
                          if (ctx.mounted) Navigator.pop(ctx);
                          _showToast(t('toastAlarmSaved'));
                        },
                        child: Text(t('btnSaveRem'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: Color(0xFFFFCDD2)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          setState(() {
                            bp.reminderIso = null;
                          });
                          await _saveBackpacks();
                          await NotificationService.instance.cancelReminder(bp.notifId);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _showToast(t('toastAlarmCleared'));
                        },
                        child: Text(t('btnClearRem'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openQuickParamsSheet() {
    final bp = _activeBackpack;
    if (bp == null) return;
    final tempAnswers = Map<String, String>.from(bp.answers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.82,
                maxChildSize: 0.92,
                minChildSize: 0.5,
                builder: (_, scrollCtrl) {
                  return ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    children: [
                      Text(t('modalParamsTitle'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.forestDark)),
                      const SizedBox(height: 4),
                      Text(t('modalParamsSub'), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      ...kQuestions.where((q) => !(q.id == 'alloggio' && tempAnswers['durata'] == 'giornata')).map((q) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (q.title[_lang] ?? q.title['it']!).toUpperCase(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forestDark),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: q.options.map((opt) {
                                  final selected = tempAnswers[q.id] == opt.val;
                                  return InkWell(
                                    onTap: () {
                                      setSheetState(() {
                                        tempAnswers[q.id] = opt.val;
                                        if (tempAnswers['durata'] == 'giornata') {
                                          tempAnswers.remove('alloggio');
                                        } else if (!tempAnswers.containsKey('alloggio')) {
                                          tempAnswers['alloggio'] = 'rifugio';
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: selected ? AppColors.forestLight : AppColors.bgStone,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: selected ? AppColors.forestPrimary : AppColors.borderSoft,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        '${opt.icon} ${opt.title[_lang] ?? opt.title['it']!}',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                          color: AppColors.forestDark,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final existingMap = <String, BackpackItem>{};
                          final customItems = <BackpackItem>[];
                          int oldCount = 0;

                          for (final it in bp.items) {
                            if (it.id.startsWith('CUST_')) {
                              customItems.add(it);
                            } else {
                              existingMap[it.id] = it;
                              oldCount++;
                            }
                          }

                          final updatedItems = <BackpackItem>[];
                          int addedCount = 0;
                          for (final m in kMasterItems) {
                            if (m.cond(tempAnswers)) {
                              if (existingMap.containsKey(m.id)) {
                                updatedItems.add(existingMap[m.id]!);
                              } else {
                                addedCount++;
                                updatedItems.add(BackpackItem(
                                  id: m.id,
                                  cat: m.cat,
                                  fallbackName: m.names['it']!,
                                ));
                              }
                            }
                          }

                          final removedCount = oldCount - (updatedItems.length - addedCount);
                          setState(() {
                            bp.answers = tempAnswers;
                            bp.items = [...updatedItems, ...customItems];
                          });
                          await _saveBackpacks();
                          await _syncActiveBackpackNotification();
                          if (ctx.mounted) Navigator.pop(ctx);
                          _showToast(t('toastUpdatedParams').replaceAll('{diff}', '+$addedCount / -$removedCount'));
                        },
                        child: Text(t('btnApplyParams'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================================
  // COSTRUZIONE SCHERMATE E GESTIONE TASTO INDIETRO ANDROID (PopScope)
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _screen == AppScreen.home,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_screen == AppScreen.wizard) {
          if (_wizardStep > 0) {
            setState(() => _wizardStep--);
          } else {
            setState(() => _screen = AppScreen.home);
          }
        } else if (_screen == AppScreen.success) {
          setState(() => _screen = AppScreen.checklist);
        } else {
          setState(() => _screen = AppScreen.home);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _buildActiveScreen(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveScreen() {
    switch (_screen) {
      case AppScreen.home:
        return _buildHomeScreen();
      case AppScreen.wizard:
        return _buildWizardScreen();
      case AppScreen.checklist:
        return _buildChecklistScreen();
      case AppScreen.success:
        return _buildSuccessScreen();
    }
  }

  Widget _buildLangAndHelpActions({bool showShare = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _openLanguageSheet,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.bgStone,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Text(
              '🌐 ${_lang.toUpperCase()}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.forestDark),
            ),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: _openGuideSheet,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.forestLight, shape: BoxShape.circle),
            child: const Text('?', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestPrimary)),
          ),
        ),
        if (showShare) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: _shareCurrentBackpack,
            icon: const Icon(Icons.ios_share, size: 20, color: AppColors.forestDark),
          ),
        ],
      ],
    );
  }

  Widget _buildDisclaimerBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️ ', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Text(
                  t('discTitle'),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            t('discText'),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.42),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // VISTA 1: HOME
  // ==========================================================================
  Widget _buildHomeScreen() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.backpack_outlined, color: AppColors.forestPrimary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Trekking Checklist',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.forestPrimary),
                  ),
                ],
              ),
              _buildLangAndHelpActions(),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            children: [
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.white, AppColors.forestLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: CustomPaint(painter: MountainBackpackPainter()),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t('homeTitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.forestDark, height: 1.2),
              ),
              const SizedBox(height: 10),
              Text(
                t('homeSub'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14.5, color: AppColors.textMuted, height: 1.45),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                onPressed: _startWizard,
                icon: const Icon(Icons.add, size: 22),
                label: Text(t('btnNewBp'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              if (_backpacks.isNotEmpty) ...[
                const SizedBox(height: 30),
                Text(
                  t('savedBpTitle').toUpperCase(),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.6),
                ),
                const SizedBox(height: 12),
                ..._backpacks.map((bp) {
                  final active = bp.items.where((i) => !i.excluded).toList();
                  final done = active.where((i) => i.done).length;
                  final pct = active.isNotEmpty ? ((done / active.length) * 100).round() : 0;
                  final dateStr = _formatShortDate(bp.createdAt);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openBackpack(bp),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _getBackpackDisplayName(bp),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.forestDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: pct == 100 ? AppColors.successLight : AppColors.forestLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$pct%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: pct == 100 ? AppColors.success : AppColors.forestPrimary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    _openConfirmDialog(
                                      title: t('confirmDeleteTitle'),
                                      description: t('confirmDelete'),
                                      onConfirm: () async {
                                        await NotificationService.instance.cancelReminder(bp.notifId);
                                        setState(() => _backpacks.removeWhere((b) => b.id == bp.id));
                                        await _saveBackpacks();
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.close, size: 19, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: active.isNotEmpty ? done / active.length : 0,
                                minHeight: 8,
                                backgroundColor: AppColors.bgStone,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forestPrimary),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$done/${active.length} ${t('completedCount')}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                                Text(dateStr, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 30),
              _buildDisclaimerBox(),
              const SizedBox(height: 22),
              const Center(
                child: Text(
                  '© 2026 Matteo Palazzi',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // VISTA 2: WIZARD DOMANDE
  // ==========================================================================
  Widget _buildWizardScreen() {
    final questions = _activeWizardQuestions;
    final q = questions[_wizardStep];
    final stepLabel = t('stepOf')
        .replaceAll('{cur}', '${_wizardStep + 1}')
        .replaceAll('{tot}', '${questions.length}');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (_wizardStep > 0) {
                    setState(() => _wizardStep--);
                  } else {
                    setState(() => _screen = AppScreen.home);
                  }
                },
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                stepLabel.toUpperCase(),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.terracotta),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLangAndHelpActions(),
                  IconButton(
                    onPressed: () => setState(() => _screen = AppScreen.home),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: List.generate(questions.length, (i) {
                  return Container(
                    width: 24,
                    height: 4,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i == _wizardStep
                          ? AppColors.terracotta
                          : (i < _wizardStep ? AppColors.forestPrimary : AppColors.borderSoft),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),
              Text(
                q.title[_lang] ?? q.title['it']!,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.forestDark),
              ),
              const SizedBox(height: 6),
              Text(
                q.desc[_lang] ?? q.desc['it']!,
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              ...q.options.map((opt) {
                final isSelected = _wizardAnswers[q.id] == opt.val;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.forestLight : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.forestPrimary : AppColors.borderSoft,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _selectWizardOption(q.id, opt.val),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Text(opt.icon, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.title[_lang] ?? opt.title['it']!,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.forestDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt.sub[_lang] ?? opt.sub['it']!,
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // VISTA 3: CHECKLIST A SCHEDE (SENZA "MIO ZAINO" RIDONDANTE IN ALTO)
  // ==========================================================================
  Widget _buildChecklistScreen() {
    final bp = _activeBackpack;
    if (bp == null) return const SizedBox.shrink();

    final active = bp.items.where((i) => !i.excluded).toList();
    final done = active.where((i) => i.done).length;
    final total = active.length;
    final pct = total > 0 ? ((done / total) * 100).round() : 0;
    final reminderItemsCount = active.where((i) => i.reminder).length;

    final curItems = active.where((i) => i.cat == _activeCategory).toList();
    final excludedItems = bp.items.where((i) => i.cat == _activeCategory && i.excluded).toList();

    String reminderText = reminderItemsCount > 0
        ? '$reminderItemsCount ${t('itemsToRemember')}'
        : t('noReminderSet');

    if (bp.reminderIso != null && DateTime.tryParse(bp.reminderIso!) != null) {
      final dt = DateTime.parse(bp.reminderIso!);
      final fDate = '${_formatShortDate(dt.millisecondsSinceEpoch)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      reminderText = '${t('alarmLabel')}: $fDate ($reminderItemsCount)';
    }

    return Column(
      children: [
        // Barra Superiore Pulita: Home a sinistra, Azioni a destra
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _screen = AppScreen.home),
                icon: const Icon(Icons.home_outlined, color: AppColors.forestDark),
              ),
              _buildLangAndHelpActions(showShare: true),
            ],
          ),
        ),

        // Intestazione Zaino con Titolo Modificabile, Progresso e Azioni Rapide
        Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  _openPromptDialog(
                    title: t('promptRename'),
                    initialValue: _getBackpackDisplayName(bp),
                    onSave: (newName) async {
                      setState(() {
                        bp.name = newName;
                        bp.isDefaultName = false;
                      });
                      await _saveBackpacks();
                      await _syncActiveBackpackNotification();
                      _showToast(t('toastRenamed'));
                    },
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _getBackpackDisplayName(bp),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.forestDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('✏️', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t('statusLabel'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                  Text('$pct% ($done/$total)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.forestPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? done / total : 0,
                  minHeight: 8,
                  backgroundColor: AppColors.bgStone,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forestPrimary),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.bgStone,
                        side: const BorderSide(color: AppColors.borderSoft),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _openConfirmDialog(
                          title: t('btnResetChecks'),
                          description: t('confirmReset'),
                          onConfirm: () async {
                            setState(() {
                              for (final it in bp.items) {
                                it.done = false;
                              }
                            });
                            await _saveBackpacks();
                            await _syncActiveBackpackNotification();
                            _showToast(t('toastReset'));
                          },
                        );
                      },
                      icon: const Text('🔄', style: TextStyle(fontSize: 13)),
                      label: Text(t('btnResetChecks'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forestDark)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.bgStone,
                        side: const BorderSide(color: AppColors.borderSoft),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _openQuickParamsSheet,
                      icon: const Text('⚙️', style: TextStyle(fontSize: 13)),
                      label: Text(t('btnEditParams'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forestDark)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Banner Verde 100%
        if (total > 0 && done == total)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('✅ ${t('inlineReadyTxt')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                InkWell(
                  onTap: () => setState(() => _screen = AppScreen.success),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(6)),
                    child: Text(t('inlineReadyBtn'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),

        // Banner Promemoria Unificato
        InkWell(
          onTap: _openReminderSheet,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.terracottaLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.terracotta),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('🔔', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reminderText,
                          style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    bp.reminderIso != null ? t('btnEditAlarm') : t('btnSetAlarm'),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Barra Orizzontale Categorie
        Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
          ),
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: kCategories.length,
            itemBuilder: (_, idx) {
              final catObj = kCategories[idx];
              final isSelected = catObj.id == _activeCategory;
              final catRemaining = active.where((i) => i.cat == catObj.id && !i.done).length;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _activeCategory = catObj.id),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.forestPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          catObj.names[_lang] ?? catObj.names['it']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            catRemaining > 0 ? '$catRemaining' : '✓',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Lista Oggetti della Categoria
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: [
              if (curItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(t('emptyCategory'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                )
              else
                ...curItems.map((item) {
                  return Opacity(
                    opacity: item.done ? 0.72 : 1.0,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: item.done ? const Color(0xFFF8FAF7) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: ListTile(
                        onTap: () => _toggleDone(item),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        leading: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: item.done ? AppColors.forestPrimary : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: item.done ? AppColors.forestPrimary : AppColors.borderSoft,
                              width: 2,
                            ),
                          ),
                          child: item.done
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                        title: Text(
                          _getItemDisplayName(item),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.8,
                            decoration: item.done ? TextDecoration.lineThrough : null,
                            color: item.done ? AppColors.textMuted : AppColors.textMain,
                          ),
                        ),
                        subtitle: item.reminder
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.terracottaLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '🔔 ${t('inReminderTag')}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _toggleItemReminder(item),
                              icon: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: item.reminder ? AppColors.terracottaLight : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('🔔', style: TextStyle(fontSize: 14)),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _excludeItem(item),
                              icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              // Cassetto Oggetti Scartati
              if (excludedItems.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(color: AppColors.borderSoft),
                TextButton(
                  onPressed: () => setState(() => _excludedExpanded = !_excludedExpanded),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${t('excludedLabel')} (${excludedItems.length}) ${_excludedExpanded ? "▴" : "▾"}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                ),
                if (_excludedExpanded)
                  ...excludedItems.map((it) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEEEA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(_getItemDisplayName(it), style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
                            ),
                            InkWell(
                              onTap: () => _restoreItem(it),
                              child: Text(
                                t('restoreBtn'),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.forestPrimary),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ],
          ),
        ),

        // Barra Inferiore Fissa: "+ Oggetto" + "💾 Finisci più tardi"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            border: Border(top: BorderSide(color: AppColors.borderSoft)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: AppColors.borderSoft),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final catName = _getCategoryDisplayName(_activeCategory);
                    _openPromptDialog(
                      title: '${t('promptCustom')} $catName?',
                      initialValue: '',
                      onSave: (name) async {
                        setState(() {
                          bp.items.add(BackpackItem(
                            id: 'CUST_${DateTime.now().millisecondsSinceEpoch}',
                            cat: _activeCategory,
                            customName: name,
                            fallbackName: name,
                          ));
                        });
                        await _saveBackpacks();
                      },
                    );
                  },
                  child: Text('+ ${t('btnAddCustom')}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.forestPrimary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showToast(t('toastSavedLater'));
                    setState(() => _screen = AppScreen.home);
                  },
                  icon: const Text('💾', style: TextStyle(fontSize: 15)),
                  label: Text(t('btnContinueLater'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // VISTA 4: SCHERMATA CELEBRATIVA 100%
  // ==========================================================================
  Widget _buildSuccessScreen() {
    final bp = _activeBackpack;
    if (bp == null) return const SizedBox.shrink();

    final active = bp.items.where((i) => !i.excluded).toList();
    final excluded = bp.items.where((i) => i.excluded).toList();
    final reminders = active.where((i) => i.reminder).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _screen = AppScreen.home),
                icon: const Icon(Icons.home_outlined),
              ),
              const Text('Trekking Checklist', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestPrimary)),
              _buildLangAndHelpActions(),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                    color: AppColors.forestPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 76, color: Colors.white),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                t('successTitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.forestPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                t('successSub'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14.5, color: AppColors.textMuted, height: 1.45),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('${active.length}', t('statReady'), AppColors.forestPrimary),
                    _buildStatCol('${excluded.length}', t('statExcluded'), AppColors.terracotta),
                    _buildStatCol('${reminders.length}', t('statRem'), AppColors.forestDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _shareCurrentBackpack,
                child: Text(t('btnShareFriends'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => setState(() => _screen = AppScreen.checklist),
                child: Text(t('btnBackBp'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _screen = AppScreen.home),
                icon: const Text('🏠'),
                label: Text(t('btnBackHome'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCol(String count, String label, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
      ],
    );
  }
}
