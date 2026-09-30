class HealthRecordAIService:

    def process(self, raw_input: str):

        text = raw_input.lower()

        suggested_data = {
            "patient_name": None,
            "age": None,
            "symptoms": [],
            "duration": None
        }

        # Extract age
        words = text.split()

        for i, word in enumerate(words):
            if word.isdigit():
                age = int(word)

                if i + 1 < len(words) and words[i + 1] in ["years", "year", "yrs", "yr"]:
                    suggested_data["age"] = age

        # Detect common symptoms
        possible_symptoms = [
            "fever",
            "headache",
            "cough",
            "cold",
            "vomiting",
            "diarrhea",
            "pain"
        ]

        for symptom in possible_symptoms:
            if symptom in text:
                suggested_data["symptoms"].append(symptom)

        # Extract duration
        if "two days" in text:
            suggested_data["duration"] = "2 days"
        elif "three days" in text:
            suggested_data["duration"] = "3 days"
        elif "one day" in text:
            suggested_data["duration"] = "1 day"

        # Basic patient-name extraction
        if " is " in raw_input:
            suggested_data["patient_name"] = raw_input.split(" is ")[0].strip()

        return suggested_data