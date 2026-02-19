import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class EmployeeList extends NavigationMixin(LightningElement) {
  employeeData = [];
  filteredEmployees = [];
  visibleEmployees = [];
  currentPage = 1;
  pageSize = 3;
  searchKey = "";

  @api
  get value() {
    return this._value;
  }

  set value(value) {
    this._value = value;
  }

  connectedCallback() {
    let employees = this.value;

    if (employees && Array.isArray(employees)) {
      this.employeeData = employees.map((emp) => ({
        ...emp,
        fullName: `${emp.firstName} ${emp.lastName}`
      }));
      this.filteredEmployees = [...this.employeeData];
      this.updateVisibleEmployees();
    } else {
      this.employeeData = [];
      this.filteredEmployees = [];
    }
  }

  get hasEmployees() {
    return this.filteredEmployees.length > 0;
  }

  get totalPages() {
    return Math.ceil(this.filteredEmployees.length / this.pageSize) || 1;
  }

  get isNextDisabled() {
    return this.currentPage >= this.totalPages;
  }

  get isPrevDisabled() {
    return this.currentPage <= 1;
  }

  updateVisibleEmployees() {
    const start = (this.currentPage - 1) * this.pageSize;
    const end = start + this.pageSize;
    this.visibleEmployees = this.filteredEmployees.slice(start, end);
  }

  handleNext() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
      this.updateVisibleEmployees();
    }
  }

  handlePrev() {
    if (this.currentPage > 1) {
      this.currentPage--;
      this.updateVisibleEmployees();
    }
  }

  handleSelectEmployee(event) {
    const recordId = event.target.dataset.empId;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        objectApiName: "Employee__c",
        actionName: "view"
      }
    });
  }

  handleSearch(event) {
    this.searchKey = event.target.value.toLowerCase();
    this.filteredEmployees = this.employeeData.filter((emp) =>
      emp.fullName.toLowerCase().includes(this.searchKey)
    );
    this.currentPage = 1;
    this.updateVisibleEmployees();
  }
}
