import { LightningElement } from 'lwc';

export default class TemplateExpressionsDemo extends LightningElement {
    firstName = 'Ada';
    lastName = 'Lovelace';
    isLoggedIn = false;

    // settings.theme intentionally omitted to show the ?? fallback
    user = { profile: { settings: {} } };

    items = [
        { name: 'Laptop', qty: 4 },
        { name: 'Monitor', qty: 0 },
        { name: 'Keyboard', qty: 12 },
        { name: 'Docking Station', qty: 0 }
    ];

    toggleLogin() {
        this.isLoggedIn = !this.isLoggedIn;
    }
}
