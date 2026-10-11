import Domain
import Foundation

extension AISamples {
    /// P10-Note's Hindi note and its English (the app signs).
    static let noteHindi = """
    नमस्ते रमेश जी, इस हफ़्ते देव ने रासायनिक समीकरण संतुलित करना सीखा। 12 में से 8 सवाल सही किए। समीकरण के आगे की संख्या \
    बदलना अभी अभ्यास में है। घर पर रोज़ 5 समीकरण करवाएँ। अगले हफ़्ते अम्ल और क्षार शुरू होंगे। धन्यवाद।
    """
    static let noteEnglish = """
    Hello Ramesh, this week Dev learnt to balance chemical equations. He got 8 of 12 questions right. Changing the \
    numbers in front is still being practised. At home, have him do 5 equations a day. Next week we start acids and \
    bases. Thank you.
    """

    /// P10-CanNowDo's Kannada note and its English.
    static let canDoKannada = """
    ನಮಸ್ಕಾರ ದೀಪಕ್ ಅವರೇ, ಈ ವಾರ ಸಾಹಿಲ್ ಚಿಕ್ಕ ವಾಕ್ಯಗಳನ್ನು ಓದಲು ಕಲಿತಿದ್ದಾನೆ. 1 ರಿಂದ 99 ರವರೆಗೆ ಎಣಿಸುತ್ತಾನೆ. ಮನೆಯಲ್ಲಿ ದಿನಕ್ಕೆ ಒಂದು ಪುಟ \
    ಓದಿಸಿ. ಧನ್ಯವಾದಗಳು.
    """
    static let canDoEnglish = """
    Hello Deepak, this week Sahil learnt to read short sentences. He counts from 1 to 99. At home, have him read one \
    page a day. Thank you.
    """

    /// P10-NotOnTrack-Message's Hindi message and its English.
    static let notOnTrackHindi = """
    नमस्ते रमेश जी, देव को समीकरण संतुलित करने में कठिनाई हो रही है और इस महीने वह दो बार अनुपस्थित रहा। हम इसे अगली कक्षा में \
    उदाहरण के साथ फिर से पढ़ाएँगे। घर पर रोज़ शाम 10 मिनट अभ्यास से बहुत फ़र्क पड़ेगा। क्या हम इस हफ़्ते 5 मिनट बात कर सकते हैं? \
    धन्यवाद।
    """
    static let notOnTrackEnglish = """
    Hello Ramesh, Dev is finding balancing equations hard and was absent twice this month. We will teach it again \
    with a worked example in the next class. Ten minutes of practice each evening at home will make a big difference. \
    Could we talk for five minutes this week? Thank you.
    """

    /// P14-Marks-Confirm's rows: Hemanth's report card, Hindi printed without a date.
    static let readMarks = [
        ReadMark(
            subject: "Mathematics",
            test: "Unit test 2",
            date: Day(year: 2026, month: 9, day: 28),
            score: 14,
            max: 25
        ),
        ReadMark(subject: "Science", test: "Unit test 2", date: Day(year: 2026, month: 9, day: 29), score: 18, max: 25),
        ReadMark(subject: "Hindi", test: "Unit test 2", date: nil, score: 11, max: 25),
    ]
}
