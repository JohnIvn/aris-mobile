/// A single Google Meet session record as returned by
/// `GET /meetings/summaries`.
class MeetTranscriptLine {
  final String t;
  final String who;
  final String text;

  const MeetTranscriptLine({
    required this.t,
    required this.who,
    required this.text,
  });

  factory MeetTranscriptLine.fromJson(Map<String, dynamic> j) =>
      MeetTranscriptLine(
        t: (j['t'] ?? '').toString(),
        who: (j['who'] ?? '').toString(),
        text: (j['text'] ?? '').toString(),
      );
}

class MeetActionItem {
  final String owner;
  final String task;
  final String due;

  const MeetActionItem({
    required this.owner,
    required this.task,
    required this.due,
  });

  factory MeetActionItem.fromJson(Map<String, dynamic> j) => MeetActionItem(
        owner: (j['owner'] ?? '').toString(),
        task: (j['task'] ?? '').toString(),
        due: (j['due'] ?? '').toString(),
      );
}

class MeetItem {
  final String id;
  final String title;
  final String course;
  final String date;
  final String time;
  final String duration;
  final List<String> participants;
  final String words;
  final String status;

  // Summary fields
  final String overview;
  final List<String> keyPoints;
  final List<String> decisions;
  final List<MeetActionItem> actions;

  // Full transcript
  final List<MeetTranscriptLine> transcript;

  final String? meetingCode;
  final String? meetingUrl;
  final bool authIn;
  final bool authOut;

  const MeetItem({
    required this.id,
    required this.title,
    required this.course,
    required this.date,
    required this.time,
    required this.duration,
    required this.participants,
    required this.words,
    required this.status,
    required this.overview,
    required this.keyPoints,
    required this.decisions,
    required this.actions,
    required this.transcript,
    this.meetingCode,
    this.meetingUrl,
    this.authIn = false,
    this.authOut = false,
  });

  factory MeetItem.fromJson(Map<String, dynamic> j) {
    List<String> toStrings(Object? v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    List<MeetActionItem> toActions(Object? v) {
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) =>
                MeetActionItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    }

    List<MeetTranscriptLine> toLines(Object? v) {
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) =>
                MeetTranscriptLine.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    }

    return MeetItem(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? 'Google Meet Session').toString(),
      course: (j['course'] ?? 'General Consultation').toString(),
      date: (j['date'] ?? '').toString(),
      time: (j['time'] ?? '').toString(),
      duration: (j['duration'] ?? '0m').toString(),
      participants: toStrings(j['participants']),
      words: (j['words'] ?? '').toString(),
      status: (j['status'] ?? 'Summarized').toString(),
      overview: (j['overview'] ?? '').toString(),
      keyPoints: toStrings(j['keyPoints']),
      decisions: toStrings(j['decisions']),
      actions: toActions(j['actions']),
      transcript: toLines(j['transcript']),
      meetingCode: j['meeting_code']?.toString(),
      meetingUrl: j['meeting_url']?.toString(),
      authIn: j['auth_in'] == true,
      authOut: j['auth_out'] == true,
    );
  }
}
