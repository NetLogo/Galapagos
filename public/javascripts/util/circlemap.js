exports.CircleMap = (function() {

    var MapNode = exports.MapNode;

    function CircleMap() {
        this.head = null;
        this.last = null;
        this.current = null;
    }

    CircleMap.prototype.append = function(nodeType) {
        var newNode = new MapNode(nodeType);
        var hashKey = this.hash(newNode.type);
        this[hashKey] = newNode;
        if (this.head === null) {
            this.head = newNode;
            this.last = newNode;
            this.current = newNode;
        } else {
            this.last.next = newNode;
            newNode.next = this.head;
            this.last = newNode;
        }
    };

    CircleMap.prototype.hash = function(value) {
        return value instanceof Object ? (value.__hash ||
            (value.__hash = 'object ' + ++arguments.callee.current)) :
            (typeof value) + ' ' + String(value);
    };

    CircleMap.prototype.get = function(type) {
        var hashKey = this.hash(type);
        return this[hashKey];
    };

    CircleMap.prototype.getCurrent = function() {
        return this.current.type;
    };

    CircleMap.prototype.setCurrent = function(type) {
        var hashKey = this.hash(type);
        this.current = this[hashKey];
    };

    //@ Slow operation...
    CircleMap.prototype.setCurrentIndex = function(index) {

        var node = this.head;
        var i = 0;

        while (i < index) {
          node = node.next;
          i++;
        }

        this.current = node;

    }

    CircleMap.prototype.next = function() {
        this.current = this.current.next;
    };

    return CircleMap;

})();
