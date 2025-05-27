import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["greeting"]
    static values = {
        username: String,
    }
    connect() {
        const hour = new Date().getHours()
        const {greeting, joke} = this.timeBasedJoke(hour)

        this.greetingTarget.innerHTML = `<div class="text-center greeting-wrapper">
                                            <div class="greeting-main">${greeting}, ${this.usernameValue}!</div>
                                          </div>`;
        // <div className="greeting-punchline">${joke}</div>
    }

    timeBasedJoke(hour) {
        const jokes = {
            morning: [
                "Why don't eggs tell jokes? They'd crack up! ☕",
                "What do you call a fake noodle? An impasta! 🍝",
                "Morning fact: Coffee is just bean soup. You're welcome. 😈"
            ],
            afternoon: [
                "Why did the cookie go to the doctor? It was feeling crumbly! 🍪",
                "What do you call a can opener that doesn't work? A can't opener! 🥫",
                "Afternoon wisdom: Keyboard shortcuts are modern-day spells ⌨️✨"
            ],
            evening: [
                "Why did the scarecrow win an award? Because he was outstanding in his field! 🌾",
                "What do you call a sleeping dinosaur? A dino-snore! 🦖",
                "Evening truth: 'Netflix and chill' is just 21st century 'come see my etchings' 📺"
            ]
        }

        if (hour >= 5 && hour < 12) {
            return {
                greeting: "Good morning",
                joke: jokes.morning[Math.floor(Math.random() * jokes.morning.length)]
            }
        } else if (hour >= 12 && hour < 17) {
            return {
                greeting: "Good afternoon",
                joke: jokes.afternoon[Math.floor(Math.random() * jokes.afternoon.length)]
            }
        } else {
            return {
                greeting: "Good evening",
                joke: jokes.evening[Math.floor(Math.random() * jokes.evening.length)]
            }
        }
    }
}
