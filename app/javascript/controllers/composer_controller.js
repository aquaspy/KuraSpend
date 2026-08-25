import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "expenseBox", "expenseForm", "expenseHeading", "expenseMethod", "expenseDelete",
    "expenseTitle", "expenseAmount", "expenseCurrency", "expenseSpentOn", "expenseCategory", "expenseNotes",
    "payBox", "payForm", "payHeading", "payMethod", "payDelete",
    "payTitle", "payDueDay", "payNotes",
    "subBox", "subForm", "subHeading", "subMethod", "subDelete",
    "subTitle", "subAmount", "subCurrency", "subInterval", "subBillingWrap", "subBillingMonth", "subDueDay", "subNotes"
  ]

  newExpense(event) {
    event?.preventDefault()
    this.fillExpense(event?.currentTarget, { create: true })
    this.expenseBoxTarget.showModal()
    this.expenseTitleTarget.focus()
  }

  editExpense(event) {
    event?.preventDefault()
    this.fillExpense(event.currentTarget)
    this.expenseBoxTarget.showModal()
    this.expenseTitleTarget.focus()
  }

  newPaymentDay(event) {
    event?.preventDefault()
    this.fillPay(event?.currentTarget, { create: true })
    this.payBoxTarget.showModal()
    this.payTitleTarget.focus()
  }

  editPaymentDay(event) {
    event?.preventDefault()
    this.fillPay(event.currentTarget)
    this.payBoxTarget.showModal()
    this.payTitleTarget.focus()
  }

  newSubscription(event) {
    event?.preventDefault()
    this.fillSub(event?.currentTarget, { create: true })
    this.subBoxTarget.showModal()
    this.subTitleTarget.focus()
  }

  editSubscription(event) {
    event?.preventDefault()
    this.fillSub(event.currentTarget)
    this.subBoxTarget.showModal()
    this.subTitleTarget.focus()
  }

  closeExpense() { this.expenseBoxTarget.close() }
  closePay() { this.payBoxTarget.close() }
  closeSub() { this.subBoxTarget.close() }

  backdrop(event) {
    if (event.target === this.expenseBoxTarget) this.closeExpense()
    if (event.target === this.payBoxTarget) this.closePay()
    if (event.target === this.subBoxTarget) this.closeSub()
  }

  toggleInterval() {
    if (!this.hasSubBillingWrapTarget || !this.hasSubIntervalTarget) return
    this.subBillingWrapTarget.hidden = this.subIntervalTarget.value !== "yearly"
  }

  fillExpense(trigger, { create } = {}) {
    const data = trigger?.dataset || {}
    const id = create ? null : data.id
    this.expenseFormTarget.action = id ? `/expenses/${id}` : "/expenses"
    this.expenseMethodTarget.value = id ? "patch" : "post"
    this.expenseHeadingTarget.textContent = data.heading || this.expenseHeadingTarget.textContent
    this.expenseTitleTarget.value = data.title || ""
    this.expenseAmountTarget.value = data.amount || ""
    if (data.currency) this.expenseCurrencyTarget.value = data.currency
    this.expenseSpentOnTarget.value = data.spentOn || this.defaultExpenseDate()
    this.expenseCategoryTarget.value = data.category || ""
    this.expenseNotesTarget.value = data.notes || ""
    if (this.hasExpenseDeleteTarget) {
      this.expenseDeleteTarget.hidden = !id
      this.expenseDeleteTarget.dataset.url = id ? `/expenses/${id}` : ""
    }
  }

  fillPay(trigger, { create } = {}) {
    const data = trigger?.dataset || {}
    const id = create ? null : data.id
    this.payFormTarget.action = id ? `/payment_days/${id}` : "/payment_days"
    this.payMethodTarget.value = id ? "patch" : "post"
    this.payHeadingTarget.textContent = data.heading || this.payHeadingTarget.textContent
    this.payTitleTarget.value = data.title || ""
    this.payDueDayTarget.value = data.dueDay || String(new Date().getDate())
    this.payNotesTarget.value = data.notes || ""
    if (this.hasPayDeleteTarget) {
      this.payDeleteTarget.hidden = !id
      this.payDeleteTarget.dataset.url = id ? `/payment_days/${id}` : ""
    }
  }

  fillSub(trigger, { create } = {}) {
    const data = trigger?.dataset || {}
    const id = create ? null : data.id
    this.subFormTarget.action = id ? `/subscriptions/${id}` : "/subscriptions"
    this.subMethodTarget.value = id ? "patch" : "post"
    this.subHeadingTarget.textContent = data.heading || this.subHeadingTarget.textContent
    this.subTitleTarget.value = data.title || ""
    this.subAmountTarget.value = data.amount || ""
    if (data.currency) this.subCurrencyTarget.value = data.currency
    this.subIntervalTarget.value = data.interval || "monthly"
    this.subBillingMonthTarget.value = data.billingMonth || "1"
    this.subDueDayTarget.value = data.dueDay || ""
    this.subNotesTarget.value = data.notes || ""
    this.toggleInterval()
    if (this.hasSubDeleteTarget) {
      this.subDeleteTarget.hidden = !id
      this.subDeleteTarget.dataset.url = id ? `/subscriptions/${id}` : ""
    }
  }

  defaultExpenseDate() {
    const today = new Date()
    const isoToday = [
      today.getFullYear(),
      String(today.getMonth() + 1).padStart(2, "0"),
      String(today.getDate()).padStart(2, "0")
    ].join("-")
    const year = Number(this.element.querySelector("input[name='year']")?.value)
    const month = Number(this.element.querySelector("input[name='month']")?.value)
    if (!year || !month) return isoToday
    if (today.getFullYear() === year && today.getMonth() + 1 === month) return isoToday
    return `${year}-${String(month).padStart(2, "0")}-01`
  }
}
