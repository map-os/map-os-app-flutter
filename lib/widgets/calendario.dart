import 'package:flutter/material.dart';
import 'package:flutter_neat_and_clean_calendar/flutter_neat_and_clean_calendar.dart';
import 'package:mapos_app/data/dashboardData.dart'; // Import the DashboardData class

class CalendarWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CalendarWidgetState();
  }
}

class _CalendarWidgetState extends State<CalendarWidget> {
  bool showEvents = true;
  List<NeatCleanCalendarEvent> _eventList = [];

  // Define getColorForStatus outside _fetchDataAndCreateEvents
  Color getColorForStatus(String status) {
    switch (status) {
      case 'Aberto':
        return Colors.black;
      case 'Orçamento':
        return Colors.blue;
      case 'Faturado':
        return Colors.deepPurple;
      case 'Negociação':
        return Colors.indigo;
      case 'Aprovado':
        return Colors.green;
      case 'Aguardando Peças':
        return Colors.brown;
      case 'Em Andamento':
        return Colors.orange;
      case 'Cancelado':
        return Colors.red;
      case 'Finalizado':
        return Color(0xff225566);
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDataAndCreateEvents();
  }

  Future<void> _fetchDataAndCreateEvents() async {
    DashboardData dashboardData = DashboardData();
    await dashboardData.fetchData(context);

    for (OSAberta osAberta in dashboardData.osAbertasList) {
      DateTime dataFinal = DateTime.parse(osAberta.dataFinal);
      _eventList.add(
        NeatCleanCalendarEvent(
          'OS ID ${osAberta.id}',
          startTime: dataFinal,
          endTime: dataFinal,
          description: 'Status: ${osAberta.status}',
          color: getColorForStatus(osAberta.status),
        ),
      );
    }

    for (OSAndamento osAndamento in dashboardData.osAndamentoList) {
      DateTime dataFinal = DateTime.parse(osAndamento.dataFinal);
      _eventList.add(
        NeatCleanCalendarEvent(
          'OS ID ${osAndamento.id}',
          isAllDay: false,
          wide: false,
          startTime: dataFinal,
          endTime: dataFinal,
          description: 'Status: ${osAndamento.status}',
          color: getColorForStatus(osAndamento.status),
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      child: Calendar(
        startOnMonday: true,
        weekDays: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'],
        eventsList: _eventList,
        isExpandable: false,
        eventDoneColor: Colors.deepPurple,
        selectedColor: Colors.blue,
        selectedTodayColor: Colors.green,
        todayColor: Colors.teal,
        eventColor: Colors.deepPurple, // Define eventColor according to your requirement
        locale: 'pt_br',
        todayButtonText: 'Agenda',
        // allDayEventText: 'Dia inteiro',
        // multiDayEndText: '', //FIM
        isExpanded: true,
        // expandableDateFormat: 'EEEE, dd. MMMM yyyy',
        onEventSelected: (value) {
          print('Evento selecionado: ${value.summary}');
        },
        onEventLongPressed: (value) {
          print('Evento pressionado por um longo tempo: ${value.summary}');
        },
        onDateSelected: (value) {
          print('Data selecionada: $value');
        },
        onRangeSelected: (value) {
          print('Intervalo selecionado: ${value.from} - ${value.to}');
        },
        // datePickerType: DatePickerType.date,
        dayOfWeekStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
        showEvents: showEvents,
      ),
    );
  }
}
