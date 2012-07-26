exports.ListNode = (function() {

    function ListNode(data, type) {
        this.data = data;
        this.next = null;
        this.prev = null;
        this.type = type;
    }

    return ListNode;

})();
