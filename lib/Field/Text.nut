class ORM.Field.Text extends ORM.Field.Basic {
    static type = "text";
    static value = "";

    /**
     * Method that encodes value
     * according to field class
     * @param  {Mixed} currentValue
     * @return {Mixed}
     */
    function encode(currentValue) {
        return currentValue.tostring();
    }

    /**
     * Method that decodes value
     * according to field class
     * @param  {Mixed} encodedValue
     * @return {Mixed}
     */
    function decode(encodedValue) {
        return encodedValue.tostring();
    }
}
