exports.DoubleList = (function() {

    var ListNode = exports.ListNode;

    function DoubleList(maxLen) {
        this.maxLen = maxLen;
        this.len = 0;
        this.head = null;
        this.tail = null;
        this.cursor = null;
        this.current = null;
    }

    DoubleList.prototype.clearCursor = function() {
        this.cursor = null;
        this.current = null;
    };

    DoubleList.prototype.addCurrent = function(cmd, agentType) {
        this.current = new ListNode(cmd, agentType);
    };

    DoubleList.prototype.append = function(text, type) {

        var newNode = new ListNode(text, type);

        if (this.head != null) {
            newNode.prev = this.head;
            this.head.next = newNode;
        }

        this.head = newNode;

        if (this.tail === null) {
            this.tail = this.head;
        }

        if (this.len < this.maxLen) {
            this.len++;
        } else {
            this.tail = this.tail.next;
            this.tail.prev = null;
        }

    };

    return DoubleList;

})();
