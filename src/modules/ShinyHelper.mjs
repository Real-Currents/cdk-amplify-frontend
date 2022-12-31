// Shiny Helper functions
'use strict';

const received_first_shiny_input = {};

export class ShinyHelper {}

export function checkShinyStatus () {
    return (
        typeof Shiny !== "undefined" &&
        typeof Shiny.setInputValue === "function"
    );
}

export function getOutput (output, callback) {
    if (!!checkShinyStatus()) try {
        Shiny.addCustomMessageHandler(output, callback || function(data) {
            console.log(`Shiny output ("${output}"):`, data);
        });
    } finally {
        return true;
    }

    return false;
}

export function setInput (input, value) {
    if (!!checkShinyStatus()) try {
        if (!!received_first_shiny_input[input]) {
            received_first_shiny_input[input] = true;
        } else {
            console.log(`Shiny input ("${input}"):`, value);
            received_first_shiny_input[input] = true;
        }
        // Shiny.setInputValue(input, value);                      // simple value update; no event for same value
        Shiny.setInputValue(input, value, { priority: "event" }); // value update with "event" priority for observeEvent
    } finally {
        return true;
    }

    return false;
}
