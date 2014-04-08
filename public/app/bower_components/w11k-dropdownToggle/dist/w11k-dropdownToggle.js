/**
 * w11k-dropdownToggle - v0.1.1 - 2014-03-29
 * https://github.com/w11k/w11k-dropdownToggle
 *
 * Copyright (c) 2014 WeigleWilczek GmbH
 */
"use strict";

angular.module("w11k.dropdownToggle", []);

angular.module("w11k.dropdownToggle").directive("w11kDropdownToggle", [ "$document", function($document) {
    var currentOpenDropdownCtrl;
    var preventCloseMenu = function(domEvent) {
        domEvent.stopPropagation();
    };
    return {
        restrict: "A",
        controller: [ "$scope", "$element", function($scope, $element) {
            var ctrl = this;
            ctrl.isOpen = false;
            var removeLocationChangeSuccessListener;
            function executeCallback(callback, domEvent) {
                var result = {
                    isPrevented: false
                };
                var event = {
                    prevent: function() {
                        result.isPrevented = true;
                    }
                };
                if (angular.isFunction(callback)) {
                    if (angular.isDefined(domEvent)) {
                        $scope.$apply(function() {
                            callback(event);
                        });
                    } else {
                        callback(event);
                    }
                }
                return result;
            }
            ctrl.shared = {};
            ctrl.open = function(domEvent) {
                var allDropdownsClosed = true;
                if (currentOpenDropdownCtrl) {
                    allDropdownsClosed = currentOpenDropdownCtrl.close();
                }
                if (domEvent) {
                    domEvent.preventDefault();
                    domEvent.stopPropagation();
                }
                if (ctrl.isOpen === false && allDropdownsClosed) {
                    var callbackResult = executeCallback(ctrl.shared.onOpen, domEvent);
                    if (callbackResult.isPrevented === false) {
                        $element.parent().addClass("open");
                        $element.parent().on("click", preventCloseMenu);
                        $document.on("click", domClose);
                        removeLocationChangeSuccessListener = $scope.$on("$locationChangeSuccess", function() {
                            ctrl.close();
                        });
                        ctrl.isOpen = true;
                        currentOpenDropdownCtrl = ctrl;
                    }
                }
                return ctrl.isOpen;
            };
            ctrl.toggle = function() {
                if (ctrl.isOpen) {
                    ctrl.close();
                } else {
                    ctrl.open();
                }
            };
            var domClose = function() {
                $scope.$apply(function() {
                    ctrl.close();
                });
            };
            function removeHandlers() {
                $element.parent().off("click", preventCloseMenu);
                $document.off("click", domClose);
                if (angular.isFunction(removeLocationChangeSuccessListener)) {
                    removeLocationChangeSuccessListener();
                    removeLocationChangeSuccessListener = undefined;
                }
            }
            ctrl.close = function(domEvent) {
                if (ctrl.isOpen) {
                    var callbackResult = executeCallback(ctrl.shared.onClose, domEvent);
                    if (callbackResult.isPrevented === false) {
                        $element.parent().removeClass("open");
                        removeHandlers();
                        ctrl.isOpen = false;
                        currentOpenDropdownCtrl = null;
                    }
                }
                return !ctrl.isOpen;
            };
            $scope.$on("$destroy", function() {
                removeHandlers();
            });
        } ],
        link: function(scope, element, attrs, ctrl) {
            var domToggle = function(domEvent) {
                domEvent.preventDefault();
                domEvent.stopPropagation();
                scope.$apply(function() {
                    ctrl.toggle();
                });
            };
            element.on("click", domToggle);
            scope.$on("$destroy", function() {
                element.off("click", domToggle);
            });
            function shareCtrlFunctions(shared) {
                shared.open = ctrl.open;
                shared.close = ctrl.close;
                shared.toggle = ctrl.toggle;
                shared.isOpen = function() {
                    return ctrl.isOpen;
                };
            }
            attrs.$observe("w11kDropdownToggle", function(attrValue) {
                if (angular.isDefined(attrValue) && attrValue !== "") {
                    var shared = scope.$eval(attrValue);
                    if (angular.isObject(shared)) {
                        ctrl.shared = shared;
                        shareCtrlFunctions(shared);
                    }
                }
            });
        }
    };
} ]);