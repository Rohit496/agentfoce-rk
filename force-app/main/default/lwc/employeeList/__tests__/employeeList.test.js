import { createElement } from "lwc";
import EmployeeList from "c/employeeList";

const MOCK_EMPLOYEES = [
  {
    id: "001",
    firstName: "John",
    lastName: "Doe",
    email: "john@example.com",
    phone: "1234567890",
    gender: "Male"
  },
  {
    id: "002",
    firstName: "Jane",
    lastName: "Smith",
    email: "jane@example.com",
    phone: "0987654321",
    gender: "Female"
  },
  {
    id: "003",
    firstName: "Alice",
    lastName: "Wonder",
    email: "alice@example.com",
    phone: "1112223333",
    gender: "Female"
  },
  {
    id: "004",
    firstName: "Bob",
    lastName: "Builder",
    email: "bob@example.com",
    phone: "4445556666",
    gender: "Male"
  }
];

// Mock NavigationMixin
const mockNavigate = jest.fn();

jest.mock(
  "lightning/navigation",
  () => {
    const Navigate = Symbol("Navigate");
    const NavigationMixin = (Base) => {
      return class extends Base {
        static [Navigate] = Navigate;
        [Navigate] = mockNavigate;
      };
    };
    NavigationMixin.Navigate = Navigate;
    return { NavigationMixin };
  },
  { virtual: true }
);

function flushPromises() {
  // eslint-disable-next-line @lwc/lwc/no-async-operation
  return new Promise((resolve) => setTimeout(resolve, 0));
}

function createComponent(employees) {
  const element = createElement("c-employee-list", { is: EmployeeList });
  element.value = employees;
  document.body.appendChild(element);
  return element;
}

describe("c-employee-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  describe("rendering with data", () => {
    it("renders employee cards when data is provided", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const employeeCards = element.shadowRoot.querySelectorAll(".employee-card");
      // pageSize is 3, so only 3 should be visible on page 1
      expect(employeeCards.length).toBe(3);
    });

    it("displays fullName for each visible employee", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const headings = element.shadowRoot.querySelectorAll(".employee-card h2");
      expect(headings[0].textContent).toBe("John Doe");
      expect(headings[1].textContent).toBe("Jane Smith");
      expect(headings[2].textContent).toBe("Alice Wonder");
    });

    it("displays email, phone, and gender details", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const details = element.shadowRoot.querySelectorAll(
        ".employee-card:first-child .emp-detail"
      );
      expect(details[0].textContent).toContain("john@example.com");
      expect(details[1].textContent).toContain("1234567890");
      expect(details[2].textContent).toContain("Male");
    });
  });

  describe("rendering without data", () => {
    it("shows no-data message when value is empty array", async () => {
      const element = createComponent([]);
      await flushPromises();

      const noDataDiv = element.shadowRoot.querySelector(
        ".slds-text-color_weak"
      );
      expect(noDataDiv).not.toBeNull();
      expect(noDataDiv.textContent).toBe("No employee data available.");
    });

    it("shows no-data message when value is null", async () => {
      const element = createComponent(null);
      await flushPromises();

      const employeeCards = element.shadowRoot.querySelectorAll(".employee-card");
      expect(employeeCards.length).toBe(0);
    });
  });

  describe("pagination", () => {
    it("displays correct page info", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const pageText = element.shadowRoot.querySelector(".page-text");
      expect(pageText.textContent).toBe("Page 1 of 2");
    });

    it("disables Previous button on first page", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const prevButton = buttons[0];
      expect(prevButton.disabled).toBe(true);
    });

    it("enables Next button when more pages exist", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const nextButton = buttons[1];
      expect(nextButton.disabled).toBe(false);
    });

    it("navigates to next page on Next click", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const nextButton = element.shadowRoot.querySelectorAll("lightning-button")[1];
      nextButton.click();
      await flushPromises();

      const pageText = element.shadowRoot.querySelector(".page-text");
      expect(pageText.textContent).toBe("Page 2 of 2");

      const employeeCards = element.shadowRoot.querySelectorAll(".employee-card");
      expect(employeeCards.length).toBe(1);

      const heading = element.shadowRoot.querySelector(".employee-card h2");
      expect(heading.textContent).toBe("Bob Builder");
    });

    it("navigates back on Previous click", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      // Go to page 2
      const nextButton = element.shadowRoot.querySelectorAll("lightning-button")[1];
      nextButton.click();
      await flushPromises();

      // Go back to page 1
      const prevButton = element.shadowRoot.querySelectorAll("lightning-button")[0];
      prevButton.click();
      await flushPromises();

      const pageText = element.shadowRoot.querySelector(".page-text");
      expect(pageText.textContent).toBe("Page 1 of 2");
    });

    it("disables Next button on last page", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const nextButton = element.shadowRoot.querySelectorAll("lightning-button")[1];
      nextButton.click();
      await flushPromises();

      expect(nextButton.disabled).toBe(true);
    });

    it("does not go beyond last page", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      // Click next twice (only 2 pages exist)
      const nextButton = element.shadowRoot.querySelectorAll("lightning-button")[1];
      nextButton.click();
      await flushPromises();
      nextButton.click();
      await flushPromises();

      const pageText = element.shadowRoot.querySelector(".page-text");
      expect(pageText.textContent).toBe("Page 2 of 2");
    });

    it("does not go before first page", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const prevButton = element.shadowRoot.querySelectorAll("lightning-button")[0];
      prevButton.click();
      await flushPromises();

      const pageText = element.shadowRoot.querySelector(".page-text");
      expect(pageText.textContent).toBe("Page 1 of 2");
    });
  });

  describe("search", () => {
    it("filters employees by name", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const searchInput = element.shadowRoot.querySelector("lightning-input");
      searchInput.value = "jane";
      searchInput.dispatchEvent(new CustomEvent("change", { detail: { value: "jane" } }));
      // handleSearch reads event.target.value, so we set it above
      await flushPromises();

      const employeeCards = element.shadowRoot.querySelectorAll(".employee-card");
      expect(employeeCards.length).toBe(1);

      const heading = element.shadowRoot.querySelector(".employee-card h2");
      expect(heading.textContent).toBe("Jane Smith");
    });

    it("resets to page 1 after search", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      // Go to page 2
      const nextButton = element.shadowRoot.querySelectorAll("lightning-button")[1];
      nextButton.click();
      await flushPromises();

      // Search
      const searchInput = element.shadowRoot.querySelector("lightning-input");
      searchInput.value = "john";
      searchInput.dispatchEvent(new CustomEvent("change"));
      await flushPromises();

      const pageText = element.shadowRoot.querySelector(".page-text");
      expect(pageText.textContent).toBe("Page 1 of 1");
    });

    it("shows no-data message when search has no results", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const searchInput = element.shadowRoot.querySelector("lightning-input");
      searchInput.value = "zzzzz";
      searchInput.dispatchEvent(new CustomEvent("change"));
      await flushPromises();

      const noDataDiv = element.shadowRoot.querySelector(".slds-text-color_weak");
      expect(noDataDiv).not.toBeNull();
    });

    it("is case-insensitive", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const searchInput = element.shadowRoot.querySelector("lightning-input");
      searchInput.value = "ALICE";
      searchInput.dispatchEvent(new CustomEvent("change"));
      await flushPromises();

      const employeeCards = element.shadowRoot.querySelectorAll(".employee-card");
      expect(employeeCards.length).toBe(1);
    });
  });

  describe("navigation", () => {
    it("navigates to employee record on button click", async () => {
      const element = createComponent(MOCK_EMPLOYEES);
      await flushPromises();

      const selectButton = element.shadowRoot.querySelector(
        "lightning-button-icon"
      );
      selectButton.dataset.empId = "001";
      selectButton.click();
      await flushPromises();

      expect(mockNavigate).toHaveBeenCalledWith({
        type: "standard__recordPage",
        attributes: {
          recordId: "001",
          objectApiName: "Employee__c",
          actionName: "view"
        }
      });
    });
  });

  describe("@api value property", () => {
    it("accepts value via setter", () => {
      const element = createElement("c-employee-list", { is: EmployeeList });
      element.value = MOCK_EMPLOYEES;
      expect(element.value).toEqual(MOCK_EMPLOYEES);
    });
  });
});
