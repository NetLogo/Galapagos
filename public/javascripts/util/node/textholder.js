exports.TextHolder = (function() {

    function TextHolder(text) {
        this.text = text;
        this.command = this.text.split("\n")[0];
        this.isExpanded = true;
    }

    TextHolder.prototype.toString = function() {
        if (this.isExpanded) {
            return this.text;
        } else {
            var result = this.command + '  ...';
            return result.bold();
        }
    };

    TextHolder.prototype.change = function() {
        this.isExpanded = !this.isExpanded;
    };

    return TextHolder;

})();
