import AccountInsights from '../components/AccountInsights.jsx';

// A server component. It renders the shell; everything that talks to Salesforce
// is inside the AccountInsights client component.
export default function Page() {
    return <AccountInsights />;
}
